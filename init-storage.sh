#!/bin/bash

# Állítsuk le a futó konténereket
echo "Leállítás..."
docker-compose down

# Biztonsági másolat készítése a régi adatokról, ha szükséges
echo "Biztonsági másolat készítése..."
docker volume inspect product_images_storage &> /dev/null
if [ $? -eq 0 ]; then
  echo "Meglévő product_images_storage volume mentése..."
  docker run --rm -v product_images_storage:/data -v $(pwd)/backup:/backup alpine tar -czf /backup/product_images_backup_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .
else
  echo "Nincs meglévő product_images_storage volume, továbblépés..."
fi

# Indítsuk újra a környezetet
echo "Újraindítás..."
docker-compose up -d

# Várjunk, amíg a szolgáltatások elindulnak
echo "Várakozás a szolgáltatások indulására..."
sleep 10

# Inicializáljuk a könyvtárakat
echo "Könyvtárak inicializálása..."
curl -s http://localhost:3002/api/api31d_checkdirectories