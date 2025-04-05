#!/bin/bash

# diagnose-nginx.sh - NGINX és fájlszerver diagnosztikai szkript   
# Futtatás: docker exec -it nginx /bin/bash -c "bash /path/to/diagnose-nginx.sh"


# adminscript01_diagnose-nginxsetupandpermissions.sh - NGINX és fájlszerver diagnosztikai szkript   
# Futtatás: docker exec -it nginx /bin/bash -c "bash docker-adminscripts/adminscript01_diagnose-nginxsetupandpermissions.sh"

echo "=== NGINX Diagnosztikai Szkript ==="
echo "Futtatás időpontja: $(date)"
echo

# Operációs rendszer és környezet
echo "=== Rendszer információk ==="
echo "Hostnév: $(hostname)"
echo "IP címek: $(hostname -I)"
echo "Kernel verzió: $(uname -r)"
echo "NGINX verzió: $(nginx -v 2>&1)"
echo

# NGINX konfiguráció ellenőrzése
echo "=== NGINX konfiguráció ellenőrzése ==="
nginx -t
echo "NGINX státusz: $(service nginx status | grep Active)"
echo

# Processzek
echo "=== Futó NGINX processzek ==="
ps aux | grep nginx
echo

# Portok ellenőrzése
echo "=== Nyitott portok ellenőrzése ==="
netstat -tulpn | grep nginx
echo

# NGINX konfiguráció részek
echo "=== NGINX konfiguráció (/etc/nginx/nginx.conf) ==="
echo "Teljes konfiguráció:"
cat /etc/nginx/nginx.conf
echo
echo "=== NGINX mime.types ==="
head -n 10 /etc/nginx/mime.types
echo "... (rövidítve) ..."
echo

# Képkönyvtár ellenőrzése
echo "=== Képkönyvtárak ellenőrzése ==="
echo "Fő képkönyvtár (/var/www/images):"
ls -la /var/www/images
echo

echo "Crawler képkönyvtár (/var/www/images/crawler):"
if [ -d "/var/www/images/crawler" ]; then
    ls -la /var/www/images/crawler
    
    # Első 3 link könyvtár listázása
    echo "Az első 3 link könyvtár:"
    find /var/www/images/crawler -type d -name "link*" | head -n 3 | while read dir; do
        echo "Könyvtár: $dir"
        ls -la "$dir" | head -n 10
        echo "..."
    done
else
    echo "A /var/www/images/crawler könyvtár nem létezik!"
fi
echo

# Jogosultságok és tulajdonosok
echo "=== Könyvtárjogosultságok és tulajdonosok ==="
echo "/var/www könyvtár:"
ls -la /var | grep www
echo

echo "/var/www/images könyvtár:"
ls -la /var/www | grep images
echo

echo "NGINX futtatási felhasználó:"
ps aux | grep "nginx: master" | awk '{print $1}'
echo

# Jogosultságellenőrzés
echo "=== Teszt fájl létrehozása ==="
TEST_FILE="/var/www/images/nginx-test-$(date +%s).txt"
echo "Test content from nginx diagnostics" > "$TEST_FILE"
echo "Teszt fájl: $TEST_FILE"
ls -la "$TEST_FILE"

# Teszt fájl elérhetőségének ellenőrzése URL-en
echo "=== Teszt fájl elérhetőségének ellenőrzése ==="
TEST_URL="http://localhost:9000/images/$(basename $TEST_FILE)"
echo "Teszt URL: $TEST_URL"
curl -I "$TEST_URL"
echo

# NGINX logok ellenőrzése
echo "=== NGINX logok ==="
echo "Access log (utolsó 5 sor):"
tail -n 5 /var/log/nginx/access.log 2>/dev/null || echo "Access log nem elérhető"
echo

echo "Error log (utolsó 10 sor):"
tail -n 10 /var/log/nginx/error.log 2>/dev/null || echo "Error log nem elérhető"
echo

# NGINX konfigurálás a képek kiszolgálására
echo "=== Javasolt NGINX konfiguráció a képek kiszolgálásához ==="
cat << 'EOF'
# Javasolt konfiguráció a /etc/nginx/nginx.conf fájlhoz:

http {
    # ... (meglévő beállítások) ...
    
    # Megfelelő MIME típusok
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    
    # Nagyobb fájlméretek engedélyezése
    client_max_body_size 50M;
    
    server {
        listen 9000;
        
        # Képek kiszolgálása
        location /images/ {
            alias /var/www/images/;
            autoindex on;
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Cache-Control' 'public, max-age=2592000';
            expires 30d;
        }
        
        # ... (többi konfiguráció) ...
    }
}
EOF
echo

echo "=== Javasolt lépések a problémák megoldására ==="
echo "1. Ellenőrizze a könyvtárjogosultságokat: chmod 755 /var/www/images és az alkönyvtárakra is"
echo "2. Ellenőrizze a fájlok jogosultságait: chmod 644 minden képfájlra"
echo "3. NGINX felhasználónak olvasási jogot kell adni: chown -R nginx:nginx /var/www/images vagy chmod -R o+r /var/www/images"
echo "4. A NGINX konfigurációban ellenőrizze a location /images/ blokkot"
echo "5. Indítsa újra az NGINX-et: nginx -s reload"

echo 
echo "=== A diagnosztika befejeződött ==="
echo "Időpont: $(date)"