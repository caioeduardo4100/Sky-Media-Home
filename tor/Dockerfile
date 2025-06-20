# Usa uma imagem leve do Debian
FROM debian:bullseye-slim

# Instala somente o Tor
RUN apt-get update && apt-get install -y tor && rm -rf /var/lib/apt/lists/*

# Copia nosso arquivo de configuração
COPY torrc /etc/tor/torrc

# CRUCIAL:
# 1. Cria o diretório do serviço oculto DURANTE O BUILD.
# 2. Define o dono e as permissões corretas (700) para ele.
RUN mkdir -p /var/lib/tor/hidden_service \
    && chown -R debian-tor:debian-tor /var/lib/tor/hidden_service \
    && chmod 700 /var/lib/tor/hidden_service

# MÁGICA DO DOCKER:
# Declara que este diretório é um volume. Quando um volume nomeado VAZIO
# é montado aqui pela primeira vez, o Docker irá COPIAR o conteúdo
# e as PERMISSÕES deste diretório da imagem para o volume.
VOLUME /var/lib/tor/hidden_service

# Roda o processo diretamente com o usuário correto.
USER debian-tor

# Comando para iniciar o Tor.
CMD ["tor"]