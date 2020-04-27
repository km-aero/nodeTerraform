#!/bin/bash

echo 'export DB_HOST: "mongodb://${db_priv_ip}:27017"' >> /home/ubuntu/.bashrc
cd /home/ubuntu/app
sudo chown -R 1000:1000 "/home/ubuntu/.npm"
sudo npm install
sudo node /home/ubuntu/app/seeds/seed.js
sudo pm2 start app.js
