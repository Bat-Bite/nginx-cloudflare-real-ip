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

# Función para agregar las direcciones IP a la configuración de Nginx
add_ip_to_nginx_config() {
  local version=$1
  local ip_ranges=("${@:2}")

  echo "# - IPv${version}" >> "$CLOUDFLARE_FILE_PATH"
  for ip in "${ip_ranges[@]}"; do
    echo "set_real_ip_from $ip;" >> "$CLOUDFLARE_FILE_PATH"
  done
}

# Agregar las direcciones IPv4 a la configuración de Nginx
add_ip_to_nginx_config 4 "${CLOUDFLARE_IPV4_RANGES[@]}"

# Agregar las direcciones IPv6 a la configuración de Nginx
add_ip_to_nginx_config 6 "${CLOUDFLARE_IPV6_RANGES[@]}"
