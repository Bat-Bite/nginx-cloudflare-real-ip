# Verificar permisos de usuario
if [[ $(id -u) -ne 0 && $(sudo -n true; echo $?) -ne 0 ]]; then
  echo "Este script debe ser ejecutado como root o con permisos de sudo."
  exit 1
fi

# Establecer lugar donde se guardara el archivo final
CLOUDFLARE_FILE_PATH=${1:-/etc/nginx/cloudflare}

# Obtener el token de API de Cloudflare
CLOUDFLARE_API_TOKEN="tu_token_de_API"

# Obtener la lista de direcciones IP de Cloudflare desde la API
CLOUDFLARE_IPV4_RANGES=$(curl -s -X GET "https://api.cloudflare.com/client/v4/ips" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  | jq -r '.result.ipv4_cidrs[]')

CLOUDFLARE_IPV6_RANGES=$(curl -s -X GET "https://api.cloudflare.com/client/v4/ips" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  | jq -r '.result.ipv6_cidrs[]')

# Agregar las direcciones IP a la configuración de Nginx
echo "# - IPv4" >> $CLOUDFLARE_FILE_PATH;
for i in $CLOUDFLARE_IPV4_RANGES; do
  echo "set_real_ip_from $i;" >> $CLOUDFLARE_FILE_PATH;
done

echo "" >> $CLOUDFLARE_FILE_PATH;
echo "# - IPv6" >> $CLOUDFLARE_FILE_PATH;
for i in $CLOUDFLARE_IPV6_RANGES; do
  echo "set_real_ip_from $i;" >> $CLOUDFLARE_FILE_PATH;
done
