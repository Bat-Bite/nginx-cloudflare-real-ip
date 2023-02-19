# Verificar que el usuario tenga permisos de root o de sudo
if [[ $EUID -ne 0 ]]; then
  echo "Este script debe ser ejecutado como root o con permisos de sudo" 1>&2
  exit 1
fi

# Verificar si jq está instalado
if ! which jq >/dev/null 2>&1; then
  echo "jq no está instalado. ¿Desea instalarlo automáticamente? (y/n)"
  read -r install_jq
  if [[ $install_jq =~ ^[Yy]$ ]]; then
    # Instalar jq automáticamente
    sudo apt-get update && sudo apt-get install -y jq
  else
    # Pedir al usuario que instale jq manualmente
    echo "Por favor, instale jq manualmente para continuar."
    exit 1
  fi
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
