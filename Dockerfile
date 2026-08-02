FROM debian:bookworm-slim@sha256:7b140f374b289a7c2befc338f42ebe6441b7ea838a042bbd5acbfca6ec875818

ENV DEBIAN_FRONTEND=noninteractive
ENV SOCKS_PORT=1051
ENV LOKINET_WORKER_THREADS=1
ENV LOKINET_HOPS=3
ENV LOKINET_PATHS=6
ENV LOKINET_UPSTREAM_DNS=9.9.9.9
ENV LOKINET_EXIT_NODE=exit.loki

# Installing build dependency
# ca-certificates are needed to validate the HTTPS connection to the Oxen repository
RUN apt-get update && apt-get install -y ca-certificates && \
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY apt /etc/apt

RUN apt-get update && apt-get install -y --no-install-recommends \
	lokinet iproute2 dante-server && \
	# Removing build dependency
	apt-get purge --auto-remove -y ca-certificates && \
	apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --chmod=755 docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE ${SOCKS_PORT}

CMD ["/docker-entrypoint.sh"]