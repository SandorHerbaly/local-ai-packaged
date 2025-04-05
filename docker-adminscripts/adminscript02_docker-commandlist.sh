# Docker parancsok a képkiszolgáló rendszer hibakeresésére és javítására

# adminscript02_docker-commandlist.sh - Docker parancs gyűjtemény rendszerhibák elhárításához
# Futtatás: bash docker-adminscripts/adminscript02_docker-commandlist.sh

# 1. Konténerek listázása és állapot ellenőrzése
docker ps
docker ps -a  # Minden konténer, beleértve a leállítottakat is

# 2. Nginx konténer közvetlen elérése
docker exec -it nginx /bin/bash

# 3. Nginx konfigurációs fájl szerkesztése
# Előbb másoljuk a konfigot a konténerből a host gépre
docker cp nginx:/etc/nginx/nginx.conf ./nginx.conf
# Módosítsuk a konfigot
# Majd másoljuk vissza
docker cp ./nginx.conf nginx:/etc/nginx/nginx.conf
# Nginx újraindítása a konténeren belül
docker exec -it nginx nginx -s reload

# 4. Képkönyvtár jogosultságok beállítása
docker exec -it nginx /bin/bash -c "chmod -R 755 /var/www/images && find /var/www/images -type f -exec chmod 644 {} \;"

# 5. Nginx naplófájlok ellenőrzése
docker exec -it nginx tail -f /var/log/nginx/error.log
docker exec -it nginx tail -f /var/log/nginx/access.log

# 6. Diagnosztikai szkript másolása és futtatása
docker cp ./diagnose-nginx.sh nginx:/tmp/diagnose-nginx.sh
docker exec -it nginx bash /tmp/diagnose-nginx.sh > nginx-diagnoszis.log

# 7. Excel-invoice-processor konténer elérése (Next.js alkalmazás)
docker exec -it excel-invoice-processor /bin/bash

# 8. A környezeti változók beállításának ellenőrzése az excel-invoice-processor konténerben
docker exec -it excel-invoice-processor env | grep IMAGE_SERVER_URL

# 9. A Next.js környezeti változóinak frissítése (ha szükséges)
# Módosítsuk a docker-compose.yml fájlt, majd:
docker-compose up -d --no-deps excel-invoice-processor

# 10. Tesztfájl létrehozása az nginx konténerben
docker exec -it nginx bash -c "echo 'Test file content' > /var/www/images/test-file.txt && chmod 644 /var/www/images/test-file.txt"
# Ellenőrizzük a teszt fájl elérhetőségét
curl http://localhost:9000/images/test-file.txt

# 11. Képfájl közvetlen átvitele a host gépről a konténerbe (tesztelési célból)
docker cp ./test-image.jpg nginx:/var/www/images/test-image.jpg
docker exec -it nginx chmod 644 /var/www/images/test-image.jpg

# 12. Crawler képkönyvtár létrehozása és tesztelése
docker exec -it nginx bash -c "mkdir -p /var/www/images/crawler/link001 && echo 'Test crawler file' > /var/www/images/crawler/link001/test.txt && chmod -R 755 /var/www/images/crawler && chmod 644 /var/www/images/crawler/link001/test.txt"
# Ellenőrizzük a teszt fájl elérhetőségét
curl http://localhost:9000/images/crawler/link001/test.txt

# 13. Hálózat ellenőrzése a konténerek között
docker network inspect demo

# 14. Teljes újraindítás, ha szükséges
docker-compose down
docker-compose up -d

# 15. Nginx konténer újraindítása
docker-compose restart nginx

# 16. Szolgáltatás naplók megtekintése
docker-compose logs -f nginx
docker-compose logs -f excel-invoice-processor

# 17. Debug API végpontok tesztelése
curl http://localhost:3002/api/carin_apis/a12n_debugImageService?imageId=link001img001
curl http://localhost:3002/api/carin_apis/a12m_debugFileServer

# 18. Könyvtárstruktúra listázása az nginx konténerben
docker exec -it nginx find /var/www/images -type d | sort

# 19. Képkönyvtár tulajdonosának módosítása
docker exec -it nginx chown -R nginx:nginx /var/www/images

# 20. Könyvtárak létezésének ellenőrzése a környezeti változók alapján
docker exec -it excel-invoice-processor bash -c 'echo $LINKS_IMAGES_PATH && ls -la $LINKS_IMAGES_PATH'