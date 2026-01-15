# 1. Use the modern Red Hat UBI 9 image with Python 3.9
FROM registry.access.redhat.com/ubi9/python-39:latest

# 2. Switch to root to perform setup (installing packages/moving files)
USER root

# 3. Set the working directory (standard for UBI Python images)
WORKDIR /opt/app-root/src

# 4. Copy source code
COPY . .

# 5. Handle the S2I scripts
# We create the directory, move the scripts, and ensure they are executable
RUN mkdir -p /tmp/scripts && \
    mv .s2i/bin/* /tmp/scripts/ && \
    chmod +x /tmp/scripts/*

# 6. Fix Permissions for OpenShift (Root Group Permissions)
# UBI images are stricter; we ensure the app root is owned by the default user (1001)
# and writable by the root group (0).
RUN rm -rf .git* && \
    chown -R 1001:0 /opt/app-root/src && \
    chmod -R g+w /opt/app-root/src && \
    chown -R 1001:0 /tmp/scripts && \
    chmod -R g+w /tmp/scripts

# 7. Switch back to the non-root user for security
USER 1001

# 8. Set Environment Variables
ENV S2I_SCRIPTS_PATH=/tmp/scripts \
    DISABLE_COLLECTSTATIC=1 \
    DISABLE_MIGRATE=1 \
    PYTHONUNBUFFERED=1

# 9. Run the Assemble script (Install dependencies)
# This assumes your 'assemble' script runs 'pip install'
RUN /tmp/scripts/assemble

# 10. Start the application
CMD [ "/tmp/scripts/run" ]
