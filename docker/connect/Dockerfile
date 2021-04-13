FROM confluentinc/cp-kafka-connect-base:6.1.1

USER root

RUN mkdir -p /opt/lenses/connect-cassandra
RUN chown -R appuser:appuser /opt/lenses

USER appuser
RUN wget https://github.com/lensesio/stream-reactor/releases/download/2.1.3/kafka-connect-cassandra-2.1.3-2.5.0-all.tar.gz -O - | tar -xz -C /opt/lenses/connect-cassandra