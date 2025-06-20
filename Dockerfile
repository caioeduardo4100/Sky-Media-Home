# 1. Base Image
# Usamos uma imagem slim do Python para manter o tamanho final pequeno.
FROM python:3.9-slim

# 2. Set Working Directory
# Define o diretório de trabalho dentro do contêiner.
WORKDIR /app

# 3. Copy Application Files
# Copia todos os arquivos do contexto atual (onde o Dockerfile está) para o /app no contêiner.
COPY ./ /app

# 4. Install Dependencies
# Instala as bibliotecas Python necessárias (neste caso, apenas Flask).
RUN pip install --no-cache-dir Flask

# 5. Create Mount Point
# Cria o diretório que será usado como um "ponto de montagem" para os vídeos do usuário.
# Isso garante que o diretório exista dentro do contêiner.
RUN mkdir -p /media/videos

# 6. Expose Port
# Informa ao Docker que o contêiner escutará na porta 5000.
EXPOSE 5000

# 7. Run Command
# O comando que será executado quando o contêiner iniciar.
# Ele inicia o servidor Flask.
CMD ["python", "app.py"]