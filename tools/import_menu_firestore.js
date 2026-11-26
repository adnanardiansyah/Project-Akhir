const fs = require('node:fs');
const path = require('node:path');

const dataPath = path.resolve(
  process.env.MENU_DATA_PATH || path.join(__dirname, 'menu_lhokseumawe.json'),
);
const args = process.argv.slice(2);

function getServiceAccountPath() {
  const inline = args.find((arg) => arg.startsWith('--service-account='));
  if (inline) {
    return path.resolve(inline.slice('--service-account='.length));
  }

  const flagIndex = args.indexOf('--service-account');
  if (flagIndex !== -1 && args[flagIndex + 1]) {
    return path.resolve(args[flagIndex + 1]);
  }

  return path.resolve(
    process.env.SERVICE_ACCOUNT_PATH ||
      process.env.GOOGLE_APPLICATION_CREDENTIALS ||
      path.join(__dirname, 'serviceAccount.json'),
  );
}

function validateData(data) {
  if (!data || !Array.isArray(data.restaurants) || data.restaurants.length === 0) {
    throw new Error('JSON harus berisi array restaurants yang tidak kosong.');
  }

  if (
    data.cleanupRestaurantIds !== undefined &&
    (!Array.isArray(data.cleanupRestaurantIds) ||
      data.cleanupRestaurantIds.some(
        (id) => typeof id !== 'string' || id.trim() === '',
      ))
  ) {
    throw new Error('cleanupRestaurantIds harus berisi array ID string.');
  }

  const restaurantIds = new Set();

  for (const restaurant of data.restaurants) {
    for (const field of ['id', 'name', 'address']) {
      if (typeof restaurant[field] !== 'string' || restaurant[field].trim() === '') {
        throw new Error(`Restaurant ${restaurant.id || '?'} memiliki field ${field} yang invalid.`);
      }
    }

    if (restaurantIds.has(restaurant.id)) {
      throw new Error(`ID restoran duplikat: ${restaurant.id}`);
    }
    restaurantIds.add(restaurant.id);

    const latitude = restaurant.location && restaurant.location.latitude;
    const longitude = restaurant.location && restaurant.location.longitude;
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) {
      throw new Error(`Lokasi restoran ${restaurant.id} tidak valid.`);
    }

    if (!Array.isArray(restaurant.menuItems) || restaurant.menuItems.length === 0) {
      throw new Error(`Restoran ${restaurant.id} tidak memiliki menuItems.`);
    }

    const menuIds = new Set();
    for (const item of restaurant.menuItems) {
      for (const field of ['id', 'name']) {
        if (typeof item[field] !== 'string' || item[field].trim() === '') {
          throw new Error(`Menu ${item.id || '?'} pada ${restaurant.id} memiliki field ${field} yang invalid.`);
        }
      }

      if (!Number.isInteger(item.price) || item.price <= 0) {
        throw new Error(`Harga menu ${item.id} pada ${restaurant.id} harus integer positif.`);
      }

      if (menuIds.has(item.id)) {
        throw new Error(`ID menu duplikat pada ${restaurant.id}: ${item.id}`);
      }
      menuIds.add(item.id);
    }
  }

  for (const id of data.cleanupRestaurantIds || []) {
    if (restaurantIds.has(id)) {
      throw new Error(`ID ${id} tidak boleh menjadi target sekaligus cleanup.`);
    }
  }
}

function countMenuItems(data) {
  return data.restaurants.reduce((total, restaurant) => total + restaurant.menuItems.length, 0);
}

function printDryRun(data, serviceAccountPath) {
  console.log('MODE: dry-run, tidak menulis ke Firestore.');
  console.log(`File data: ${dataPath}`);
  console.log(`File service account: ${serviceAccountPath}`);
  console.log(`Restoran: ${data.restaurants.length}`);
  console.log(`Menu: ${countMenuItems(data)}`);

  for (const restaurant of data.restaurants) {
    const mode = restaurant.updateRestaurant === false ? 'menu saja' : 'restoran + menu';
    console.log(`- ${restaurant.id}: ${restaurant.menuItems.length} menu (${mode})`);
  }

  const cleanupIds = data.cleanupRestaurantIds || [];
  console.log(`Dokumen dibersihkan: ${cleanupIds.length}`);
  for (const id of cleanupIds) {
    console.log(`- hapus ${id}`);
  }

  console.log('Gunakan npm run menu:apply untuk menulis ke Firestore.');
}

async function commitOperations(db, operations) {
  for (let index = 0; index < operations.length; index += 450) {
    const batch = db.batch();
    const chunk = operations.slice(index, index + 450);

    for (const operation of chunk) {
      if (operation.type === 'delete') {
        batch.delete(operation.ref);
      } else if (operation.options) {
        batch.set(operation.ref, operation.data, operation.options);
      } else {
        batch.set(operation.ref, operation.data);
      }
    }

    await batch.commit();
  }
}

async function backUpMenuItems(db, data) {
  const backup = {
    createdAt: new Date().toISOString(),
    restaurants: [],
  };

  const backupIds = [
    ...new Set([
      ...data.restaurants.map((restaurant) => restaurant.id),
      ...(data.cleanupRestaurantIds || []),
    ]),
  ];

  for (const id of backupIds) {
    const reference = db.collection('restaurants').doc(id);
    const document = await reference.get();
    const snapshot = await reference.collection('menuItems').get();

    backup.restaurants.push({
      id,
      name: (document.data() || {}).name || '',
      menuItems: snapshot.docs.map((menuDocument) => ({
        id: menuDocument.id,
        ...menuDocument.data(),
      })),
    });
  }

  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const backupPath = path.join(__dirname, `menu_backup_${stamp}.json`);
  fs.writeFileSync(backupPath, JSON.stringify(backup, null, 2));
  return backupPath;
}

async function deleteCleanupRestaurants(db, ids) {
  for (const id of ids) {
    const reference = db.collection('restaurants').doc(id);
    const collections = await reference.listCollections();

    for (const collection of collections) {
      const documents = await collection.listDocuments();
      await commitOperations(
        db,
        documents.map((document) => ({ type: 'delete', ref: document })),
      );
    }

    await reference.delete();
    console.log(`${id}: dokumen dihapus.`);
  }
}

async function applyData(data, serviceAccountPath) {
  const { initializeApp, cert } = require('firebase-admin/app');
  const { getFirestore, GeoPoint } = require('firebase-admin/firestore');
  const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));

  if (!serviceAccount.project_id) {
    throw new Error('File service account tidak memiliki project_id.');
  }

  const app = initializeApp({
    credential: cert(serviceAccount),
  });

  const db = getFirestore(app);
  const backupPath = await backUpMenuItems(db, data);
  console.log(`Backup menu lama: ${backupPath}`);

  const restaurantOperations = data.restaurants
    .filter((restaurant) => restaurant.updateRestaurant !== false)
    .map((restaurant) => ({
      type: 'set',
      ref: db.collection('restaurants').doc(restaurant.id),
      data: {
        name: restaurant.name,
        address: restaurant.address,
        location: new GeoPoint(
          restaurant.location.latitude,
          restaurant.location.longitude,
        ),
      },
      options: { merge: true },
    }));

  if (restaurantOperations.length > 0) {
    await commitOperations(db, restaurantOperations);
    console.log(`Restoran diperbarui: ${restaurantOperations.length}`);
  } else {
    console.log('Data restoran tidak diubah.');
  }

  for (const restaurant of data.restaurants) {
    const reference = db.collection('restaurants').doc(restaurant.id).collection('menuItems');
    const existingDocuments = await reference.listDocuments();
    const deleteOperations = existingDocuments.map((document) => ({
      type: 'delete',
      ref: document,
    }));
    await commitOperations(db, deleteOperations);

    const setOperations = restaurant.menuItems.map((item) => ({
      type: 'set',
      ref: reference.doc(item.id),
      data: {
        name: item.name,
        price: item.price,
      },
    }));
    await commitOperations(db, setOperations);

    console.log(`${restaurant.id}: ${existingDocuments.length} menu lama dihapus, ${setOperations.length} menu baru ditulis.`);
  }

  await deleteCleanupRestaurants(db, data.cleanupRestaurantIds || []);
  console.log(`Selesai. Total menu baru: ${countMenuItems(data)}`);
}

async function main() {
  const data = JSON.parse(fs.readFileSync(dataPath, 'utf8'));
  validateData(data);

  const serviceAccountPath = getServiceAccountPath();

  if (!args.includes('--apply') || args.includes('--dry-run')) {
    printDryRun(data, serviceAccountPath);
    return;
  }

  if (!fs.existsSync(serviceAccountPath)) {
    throw new Error(`File service account tidak ditemukan: ${serviceAccountPath}`);
  }

  await applyData(data, serviceAccountPath);
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
