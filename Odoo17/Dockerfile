# Multi-stage Dockerfile for Odoo 17
FROM python:3.11-slim-bullseye as base

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    wget \
    gosu \
    dos2unix \
    libxml2-dev \
    libxslt-dev \
    libldap2-dev \
    libsasl2-dev \
    libssl-dev \
    libffi-dev \
    libjpeg-dev \
    libpq-dev \
    zlib1g-dev \
    libfreetype6-dev \
    liblcms2-dev \
    libopenjp2-7-dev \
    libtiff5-dev \
    libwebp-dev \
    libpng-dev \
    fontconfig \
    fonts-dejavu-core \
    fonts-freefont-ttf \
    fonts-liberation \
    fonts-noto-cjk \
    locales \
    postgresql-client \
    node-less \
    npm \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Generate locale
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Install rtlcss for right-to-left CSS support
RUN npm install -g rtlcss

# Install wkhtmltopdf for PDF reports
RUN curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.bullseye_amd64.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Create odoo user and directories
RUN groupadd -r odoo && useradd -r -g odoo odoo
RUN mkdir -p /opt/odoo /var/lib/odoo /var/log/odoo \
    && chown -R odoo:odoo /opt/odoo /var/lib/odoo /var/log/odoo

# Set working directory
WORKDIR /opt/odoo

# Copy requirements and install Python dependencies
COPY requirements.txt .
# Fix pkg_resources deprecation warning by upgrading setuptools
RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir "setuptools<81" \
    && pip install --no-cache-dir -r requirements.txt

# Copy custom entrypoint first (as root)
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh && \
    dos2unix /docker-entrypoint.sh 2>/dev/null || true && \
    ls -la /docker-entrypoint.sh

# Copy scripts directory (as root)
COPY scripts/ /scripts/
RUN chmod +x /scripts/*.sh && \
    dos2unix /scripts/*.sh 2>/dev/null || true && \
    ls -la /scripts/

# Copy Odoo source code (excluding Docker files to avoid conflicts)
COPY --chown=odoo:odoo addons/ /opt/odoo/addons/
COPY --chown=odoo:odoo custom_addons/ /opt/odoo/custom_addons/
COPY --chown=odoo:odoo odoo/ /opt/odoo/odoo/
COPY --chown=odoo:odoo odoo-bin /opt/odoo/odoo-bin
COPY --chown=odoo:odoo odoo.conf /opt/odoo/odoo.conf
COPY --chown=odoo:odoo setup.py /opt/odoo/setup.py
COPY --chown=odoo:odoo setup.cfg /opt/odoo/setup.cfg

# Make odoo-bin executable
RUN chmod +x /opt/odoo/odoo-bin

# Create directories for addons and filestore
RUN mkdir -p /var/lib/odoo/addons /var/lib/odoo/filestore \
    && chown -R odoo:odoo /var/lib/odoo

# Expose Odoo port
EXPOSE 8069 8072

# Switch to odoo user
USER odoo

# Set environment variables
ENV ODOO_RC=/opt/odoo/odoo.conf \
    ODOO_BASE_PATH=/opt/odoo \
    ODOO_ADDONS_PATH=/opt/odoo/addons,/opt/odoo/custom_addons \
    ODOO_DATA_DIR=/var/lib/odoo

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=300s --retries=5 \
    CMD curl -f http://localhost:8069/web/database/selector || curl -f http://localhost:8069/ || exit 1

# Default command
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["odoo"]