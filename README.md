🚀 aaPanel OpenLiteSpeed Tuning Script

This script automates the process of applying high-performance and robust logging configurations to websites running on OpenLiteSpeed within the aaPanel environment. It's designed to take a default site configuration and apply a consistent set of best-practice tunings with a single command.
🎯 Target Environment

This script is specifically designed for servers with the following stack:

    Control Panel: aaPanel

    Web Server: OpenLiteSpeed

    Operating System: Red Hat-based Linux (Rocky Linux 8+, AlmaLinux 8+, etc.)

    Database: MariaDB or MySQL (installed via aaPanel)

🛠️ Key Features & Automated Actions

Running this script will perform the following optimizations on the specified virtual host:

    Automated Backups: Creates a one-time .orig backup of the original config and a timestamped .bak backup on every run.

    LSAPI Process Tuning: Updates the extprocessor block with optimized values for maxConns, LSAPI_CHILDREN, memory limits, and timeouts.

    Customized Logging: Replaces default log configurations, creating dedicated, per-site log directories and files with robust rotation settings.

    Per-Site PHP Configuration: Replaces the phpIniOverride block to set secure production error logging and increase resource limits (memory_limit, upload_max_filesize, etc.).

    LSCache Configuration: Adds or replaces the module cache block with optimized settings for public caching.

⚙️ Installation & Usage
Step 1: Download the Script

Log into your server via SSH and download the script from your GitHub repository.

wget -O tunescript.sh https://github.com/fueledbybits/vhost-tunning-aapanel/raw/refs/heads/main/vhost-tunning.sh

Step 2: Make it Executable

chmod +x tunescript.sh

Step 3: Run the Script

Execute the script with sudo privileges. It requires two arguments: the exact domain name of the site and a size profile (Site trafic size).

Syntax:

sudo ./tunescript.sh <domain_name> <high|medium|small>

Example:

sudo ./tunescript.sh site.com big


⚠️ IMPORTANT: Final Step After Running

After the script completes successfully, a graceful restart of the OpenLiteSpeed service is required for all changes to take effect. Run the following command:

sudo /usr/local/lsws/bin/lswsctrl restart

