<h1>🚀 aaPanel OpenLiteSpeed Tuning Script</h1>

This script automates the process of applying high-performance and robust logging configurations to websites running on OpenLiteSpeed within the aaPanel environment. It's designed to take a default site configuration and apply a consistent set of best-practice tunings with a single command.
🎯 Target Environment

This script is specifically designed for servers with the following stack:

    Control Panel: aaPanel

    Web Server: OpenLiteSpeed

    Operating System: Red Hat-based Linux (Rocky Linux 8+, AlmaLinux 8+, etc.)

    Database: MariaDB or MySQL (installed via aaPanel)

<h1>🛠️ Key Features & Automated Actions</h1>

Running this script will perform the following optimizations on the specified virtual host:

<ul>
    <li><strong>Automated Backups:</strong> Creates a one-time <code>.orig</code> backup of the original config and a timestamped <code>.bak</code> backup on every run.</li>
    <li><strong>LSAPI Process Tuning:</strong> Updates the <code>extprocessor</code> block with optimized values for <code>maxConns</code>, <code>LSAPI_CHILDREN</code>, memory limits, and timeouts.</li>
    <li><strong>Customized Logging:</strong> Replaces default log configurations, creating dedicated, per-site log directories and files with robust rotation settings.</li>
    <li><strong>Per-Site PHP Configuration:</strong> Replaces the <code>phpIniOverride</code> block to set secure production error logging and increase resource limits (<code>memory_limit</code>, <code>upload_max_filesize</code>, etc.).</li>
    <li><strong>LSCache Configuration:</strong> Adds or replaces the module <code>cache</code> block with optimized settings for public caching.</li>
</ul>

<h2>⚙️ Installation & Usage</h2>


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


<b style="color:red;">⚠️ IMPORTANT: Final Step After Running</b>

After the script completes successfully, a graceful restart of the OpenLiteSpeed service is required for all changes to take effect. Run the following command:

    sudo /usr/local/lsws/bin/lswsctrl restart

