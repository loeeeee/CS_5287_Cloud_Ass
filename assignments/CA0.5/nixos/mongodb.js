// /etc/nixos/initialize-mongo.js
db = db.getSiblingDB('admin');
db.createUser({
  user: 'admin',
  pwd: 'A_SEHR_SAFE_PASSWORD', // Replace with a strong, unique password
  roles: [{ role: 'root', db: 'admin' }],
});