#!/bin/bash
# ==============================================================================
# aaPanel OpenLiteSpeed Virtual Host Tuner (v2)
# ==============================================================================
#
# Description:
# This script applies performance and logging optimizations to a specific
# website's OpenLiteSpeed virtual host configuration file within an aaPanel
# environment.
#
# Usage:
#   sudo ./tunescript.sh <vhost_name> <site_size>
#
# Examples:
#   sudo ./tunescript.sh example.com high
#   sudo ./tunescript.sh example.net small
#
# Author: Boris Lucas
# Date: June 16, 2025
#
# ==============================================================================

# --- Function to display messages ---
log() {
    echo "[INFO] $1"
}
log-empty() {
    echo "[INFO] $1"
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

# --- 1. SCRIPT SETUP AND VALIDATION ---

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run with root privileges. Please use sudo."
fi

# Check for correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "[ERROR] Invalid arguments."
    echo "Usage: sudo $0 <vhost_name> <site_size>"
    echo "Example: sudo $0 site.com high"
    echo "Site sizes can be: high, medium, or small."
    exit 1
fi

VH_NAME=$1
SITE_SIZE=$(echo "$2" | tr '[:upper:]' '[:lower:]') # Convert site_size to lowercase
VHOST_CONF="/www/server/panel/vhost/openlitespeed/detail/${VH_NAME}.conf"
LOG_DIR="/www/wwwlogs/${VH_NAME}"
VH_ROOT="/www/wwwroot"
CACHE_DIR="${VH_ROOT}/cache/${VH_NAME}/lscache"

# Check if the virtual host configuration file exists
log "Checking for virtual host configuration file at ${VHOST_CONF}..."
if [ ! -f "$VHOST_CONF" ]; then
    error "Virtual host configuration file not found at: $VHOST_CONF"
fi

# --- Create a one-time backup of the original file ---
# This runs only if the .orig file does not already exist.
if [ ! -f "${VHOST_CONF}.orig" ]; then
    log "Creating one-time backup of original file: ${VHOST_CONF}.orig"
    cp "$VHOST_CONF" "${VHOST_CONF}.orig"
fi

# --- Create a timestamped backup for every script run ---
# This captures the state of the file before each new set of changes.
TIMESTAMP=$(date +%F_%H-%M-%S) # e.g., 2025-06-16_20-30-00
log "Creating VH config timestamped backup: ${VHOST_CONF}.bak_tuning_${TIMESTAMP}"
cp "$VHOST_CONF" "${VHOST_CONF}.bak_tuning_${TIMESTAMP}"



# --- 2. CREATE AND CONFIGURE NEW LOG DIRECTORY ---
# Check for the log directory
log "Checking for log directory at ${LOG_DIR}..."
if [ ! -d "$LOG_DIR" ]; then
    log "Log directory not found. Creating..."
    mkdir -p "$LOG_DIR"
    chown www:www "$LOG_DIR"
    chmod 700 "$LOG_DIR"
    log "Log directory created and permissions set."
else
    log "Log directory already exists. Skipping."
fi

# Check for the cache directory
log "Checking for cache directory at ${CACHE_DIR}..."
if [ ! -d "$CACHE_DIR" ]; then
    log "Cache directory not found. Creating..."
    mkdir -p "$CACHE_DIR"
    chown -R www:www "${VH_ROOT}/cache/"
    chmod -R 700 "${VH_ROOT}/cache/"

    log "Cache directory created and permissions set."
else
    log "Cache directory already exists. Skipping."
fi

# --- 3. DEFINE CONFIGURATIONS BASED ON SITE SIZE ---

# This structure makes it easy to add different values for 'medium' or 'small' later.
case "$SITE_SIZE" in
    high)
        # LSAPI Processor Settings
        MAX_CONNS="200"
        LSAPI_CHILDREN="200"
        INIT_TIMEOUT="300"
        KEEPALIVE_TIMEOUT="30"
        MEM_SOFT_LIMIT="6144M"
        MEM_HARD_LIMIT="6144M"
        PROC_SOFT_LIMIT="800"
        PROC_HARD_LIMIT="900"

    # Define the logging blocks
    ERROR_LOG_BLOCK="""
errorlog ${LOG_DIR}/ols-error.log {
    useServer               0
    logLevel                NOTICE
    rollingSize             500M
    keepDays                10
    compressArchive         1
}""" 

    ACCESS_LOG_BLOCK="""
accesslog ${LOG_DIR}/ols-access.log {
    useServer               0
    logFormat               '%{X-Forwarded-For}i %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"'
    logHeaders              6
    rollingSize             500M
    keepDays                10
    compressArchive         1
}"""

        # Construct the full phpIniOverride block
        PHP_INI_OVERRIDES="""phpIniOverride  {
    php_admin_value open_basedir \"/tmp/:/www/wwwroot/${VH_NAME}/\"
    php_admin_value memory_limit \"512M\"
    php_admin_value upload_max_filesize \"64M\"
    php_admin_value post_max_size \"64M\"
    php_admin_value max_execution_time \"300\"
    php_admin_value max_input_time \"90\"
    php_admin_value error_log \"${LOG_DIR}/php-error.log\"
    php_admin_value log_errors \"On\"
    php_admin_value error_reporting \"E_ALL & ~E_DEPRECATED & ~E_STRICT\"
    php_admin_value display_errors \"Off\"
}"""

        # Construct the full module cache block
        CACHE_MODULE_BLOCK="""
module cache {
    storagePath             $VH_ROOT/cache/${VH_NAME}/lscache
    ls_enabled              1

    checkPrivateCache       0
    checkPublicCache        1
    maxCacheObjSize         10000000
    maxStaleAge             200

    qsCache                 1
    reqCookieCache          1
    respCookieCache         1

    ignoreReqCacheCtrl      1
    ignoreRespCacheCtrl     0

    enableCache             1
    expireInSeconds         3600
    enablePrivateCache      0
    privateExpireInSeconds  3600
}"""
        ;;
    medium)
        # LSAPI Processor Settings
        MAX_CONNS="100"
        LSAPI_CHILDREN="100"
        INIT_TIMEOUT="90"
        KEEPALIVE_TIMEOUT="15"
        MEM_SOFT_LIMIT="4096M"
        MEM_HARD_LIMIT="4096M"
        PROC_SOFT_LIMIT="600"
        PROC_HARD_LIMIT="700"

    # Define the logging blocks
    ERROR_LOG_BLOCK="""
errorlog ${LOG_DIR}/ols-error.log {
    useServer               0
    logLevel                NOTICE
    rollingSize             500M
    keepDays                10
    compressArchive         1
}"""

    ACCESS_LOG_BLOCK="""
accesslog ${LOG_DIR}/ols-access.log {
    useServer               0
    logFormat               '%{X-Forwarded-For}i %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"'
    logHeaders              6
    rollingSize             500M
    keepDays                10
    compressArchive         1
}"""

        # Construct the full phpIniOverride block
        PHP_INI_OVERRIDES="""phpIniOverride  {
    php_admin_value open_basedir \"/tmp/:/www/wwwroot/${VH_NAME}/\"
    php_admin_value memory_limit \"256M\"
    php_admin_value upload_max_filesize \"32M\"
    php_admin_value post_max_size \"32M\"
    php_admin_value max_execution_time \"180\"
    php_admin_value max_input_time \"60\"
    php_admin_value error_log \"${LOG_DIR}/php-error.log\"
    php_admin_value log_errors \"On\"
    php_admin_value error_reporting \"E_ALL & ~E_DEPRECATED & ~E_STRICT\"
    php_admin_value display_errors \"Off\"
}"""

        # Construct the full module cache block
        CACHE_MODULE_BLOCK="""
module cache {
    storagePath             $VH_ROOT/cache/${VH_NAME}/lscache
    ls_enabled              1

    checkPrivateCache       0
    checkPublicCache        1
    maxCacheObjSize         5000000
    maxStaleAge             180

    qsCache                 1
    reqCookieCache          1
    respCookieCache         1

    ignoreReqCacheCtrl      1
    ignoreRespCacheCtrl     0

    enableCache             1
    expireInSeconds         3600
    enablePrivateCache      0
    privateExpireInSeconds  3600
}"""
        ;;
    small)
        # LSAPI Processor Settings
        MAX_CONNS="20"
        LSAPI_CHILDREN="40"
        INIT_TIMEOUT="60"
        KEEPALIVE_TIMEOUT="15"
        MEM_SOFT_LIMIT="2047M"
        MEM_HARD_LIMIT="2047M"
        PROC_SOFT_LIMIT="400"
        PROC_HARD_LIMIT="500"

    # Define the logging blocks
    ERROR_LOG_BLOCK="""
errorlog ${LOG_DIR}/ols-error.log {
    useServer               0
    logLevel                NOTICE
    rollingSize             500M
    keepDays                10
    compressArchive         1
}"""

    ACCESS_LOG_BLOCK="""
accesslog ${LOG_DIR}/ols-access.log {
    useServer               0
    logFormat               '%{X-Forwarded-For}i %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"'
    logHeaders              6
    rollingSize             500M
    keepDays                10
    compressArchive         1
}"""

        # Construct the full phpIniOverride block
        PHP_INI_OVERRIDES="""phpIniOverride  {
    php_admin_value open_basedir \"/tmp/:/www/wwwroot/${VH_NAME}/\"
    php_admin_value memory_limit \"128M\"
    php_admin_value upload_max_filesize \"16M\"
    php_admin_value post_max_size \"16M\"
    php_admin_value max_execution_time \"60\"
    php_admin_value max_input_time \"60\"
    php_admin_value error_log \"${LOG_DIR}/php-error.log\"
    php_admin_value log_errors \"On\"
    php_admin_value error_reporting \"E_ALL & ~E_DEPRECATED & ~E_STRICT\"
    php_admin_value display_errors \"Off\"
}"""

        # Construct the full module cache block
        CACHE_MODULE_BLOCK="""
module cache {
    storagePath             $VH_ROOT/cache/${VH_NAME}/lscache
    ls_enabled              1

    checkPrivateCache       0
    checkPublicCache        1
    maxCacheObjSize         2000000
    maxStaleAge             200

    qsCache                 1
    reqCookieCache          1
    respCookieCache         1

    ignoreReqCacheCtrl      1
    ignoreRespCacheCtrl     0

    enableCache             1
    expireInSeconds         3600
    enablePrivateCache      0
    privateExpireInSeconds  3600
}"""
        ;;
    *)
        error "Invalid site traffic size. Please use 'high', 'medium', or 'small'."
        ;;
esac


# --- 4. UPDATE AAPANEL LOG PATHS ---
update_aapanel_log_paths() {
    log "Updating aaPanel log paths..."
    local V1="/www/server/panel/class/panelSite.py"
    local V2="/www/server/panel/class_v2/panel_site_v2.py"
    local files_to_patch=()

    # Check which files exist
    [ -f "$V1" ] && files_to_patch+=("$V1")
    [ -f "$V2" ] && files_to_patch+=("$V2")

    if [ ${#files_to_patch[@]} -eq 0 ]; then
        log "No aaPanel site management files found to patch. Skipping."
        return
    fi

    for file in "${files_to_patch[@]}"; do
        # Create a one-time backup
        if [ ! -f "${file}.vhost_tunning_bak" ]; then
            log "Creating backup for ${file}..."
            cp "$file" "${file}.vhost_tunning_bak"
        fi

        # Check if patching is needed before applying sed
        if grep -q "'/www/wwwlogs/'[[:space:]]*+[[:space:]]*get.siteName[[:space:]]*+[[:space:]]*'_ols\." "$file"; then
            log "Patching OLS log paths in ${file}..."
            # Update OLS access log path
            sed -i "s|'/www/wwwlogs/'[[:space:]]*+[[:space:]]*get.siteName[[:space:]]*+[[:space:]]*'_ols\.access_log'|'/www/wwwlogs/' + get.siteName + '/ols-access.log'|g" "$file"
            # Update OLS error log path
            sed -i "s|'/www/wwwlogs/'[[:space:]]*+[[:space:]]*get.siteName[[:space:]]*+[[:space:]]*'_ols\.error_log'|'/www/wwwlogs/' + get.siteName + '/ols-error.log'|g" "$file"
            log "Finished patching ${file}."
        else
            log "Log paths in ${file} appear to be already updated. Skipping patch."
        fi
    done
}

# Call the function to update aaPanel paths
update_aapanel_log_paths


# --- 5. APPLY CHANGES TO VHOST CONFIGURATION FILE ---
log "Applying optimizations to ${VHOST_CONF}..."


# Modify the extprocessor block using sed for precision.
log "Tuning the extprocessor block..."
sed -i "s/^\( *maxConns *\).*/\1${MAX_CONNS}/" "$VHOST_CONF"
sed -i "s/^\( *env *LSAPI_CHILDREN=\).*/\1${LSAPI_CHILDREN}/" "$VHOST_CONF"
sed -i "s/^\( *initTimeout *\).*/\1${INIT_TIMEOUT}/" "$VHOST_CONF"
sed -i "s/^\( *pcKeepAliveTimeout *\).*/\1${KEEPALIVE_TIMEOUT}/" "$VHOST_CONF"
sed -i "s/^\( *memSoftLimit *\).*/\1${MEM_SOFT_LIMIT}/" "$VHOST_CONF"
sed -i "s/^\( *memHardLimit *\).*/\1${MEM_HARD_LIMIT}/" "$VHOST_CONF"
sed -i "s/^\( *procSoftLimit *\).*/\1${PROC_SOFT_LIMIT}/" "$VHOST_CONF"
sed -i "s/^\( *procHardLimit *\).*/\1${PROC_HARD_LIMIT}/" "$VHOST_CONF"

# Replace the phpIniOverride, logs, cache blocks to ensure it's always up-to-date.
log "Implementing New Configurations..."

# Delete existing configuration to ensure a clean slate.
sed -i '/^errorlog.*{/,/^\s*}/d' "$VHOST_CONF"
sed -i '/^accesslog.*{/,/^\s*}/d' "$VHOST_CONF"
sed -i '/^phpIniOverride[[:space:]]*{/,/}/d' "$VHOST_CONF"
sed -i '/^module cache[[:space:]]*{/,/}/d' "$VHOST_CONF"

# Append all new configurations blocks to the end of the file.
{
    echo ""
    echo "$ERROR_LOG_BLOCK"
    echo "$ACCESS_LOG_BLOCK"
    echo "$PHP_INI_OVERRIDES"
    echo "$CACHE_MODULE_BLOCK"
} >> "$VHOST_CONF"


# --- 6. CLEAN UP OLD LOG FILES ---
log "Cleaning up old default log files in old directory..."
if [ -f "/www/wwwlogs/${VH_NAME}_ols.error_log" ]; then
    rm -f "/www/wwwlogs/${VH_NAME}_ols.error_log"
    log "Removed old error log."
fi
if [ -f "/www/wwwlogs/${VH_NAME}_ols.access_log" ]; then
    rm -f "/www/wwwlogs/${VH_NAME}_ols.access_log"
    log "Removed old access log."
fi

# --- 7. RESTARTING LITESPEED SERVER ---
log "Restarting LiteSpeed server..."
if ! sudo /usr/local/lsws/bin/lswsctrl restart; then
    error "LiteSpeed restart failed. Please check the configuration."
fi

# --- 8. RESTARTING AAPANEL ---
log "Restarting aaPanel for changes to take effect..."
if ! sudo bt restart; then
    log "[WARNING] aaPanel restart failed. You may need to restart it manually from the command line with 'bt restart'."
fi

# --- FINAL INSTRUCTIONS ---
echo
echo "========================================================================"
echo "    >>> SITE TUNING SCRIPT COMPLETE <<<"
echo "========================================================================"
echo
echo "Successfully applied optimizations for: ${VH_NAME}"
echo "Using profile: ${SITE_SIZE}"
echo
echo
echo "========================================================================"
# --- End of Script ---
