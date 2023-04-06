#!/bin/bash

cd /home/ec2-user/script
touch ./.env

echo "DB_HOST=$(echo ${DB_HOST} | cut -d ':' -f 1)" >> .env
echo "DB_USER=${DB_USER}" >> .env
echo "DB_PASSWORD=${DB_PASSWORD}" >> .env
echo "S3_BUCKET_NAME=${S3_BUCKET_NAME}" >> .env

sudo su
cd /
mkdir ./upload
sudo chown ec2-user:ec2-user /home/ec2-user/script/*
sudo systemctl stop node.service
sudo systemctl daemon-reload
sudo systemctl enable node.service
sudo systemctl start node.service

source ./.env