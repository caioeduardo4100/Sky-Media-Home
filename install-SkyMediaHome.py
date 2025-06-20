import os
import subprocess
import time
import sys
from pathlib import Path
import shutil

# Definições de cores ANSI para o terminal
class Cores:
    VERDE = '\033[92m'
    AMARELO = '\033[93m'
    CIANO = '\033[96m'
    RESET = '\033[0m'

def imprimir_cabecalho(titulo):
    """Imprime um cabeçalho formatado."""
    print(f"\n{Cores.CIANO}{'='*60}{Cores.RESET}")
    print(f"{Cores.CIANO}{titulo.center(60)}{Cores.RESET}")
    print(f"{Cores.CIANO}{'='*60}{Cores.RESET}\n")

def verificar_docker():
    """Verifica se o docker-compose está instalado e acessível."""
    imprimir_cabecalho("PASSO 0: VERIFICANDO O DOCKER")
    print("Verificando se o Docker Compose está instalado e acessível...")
    if not shutil.which("docker-compose"):
        print(f"{Cores.AMARELO}ERRO: O comando 'docker-compose' não foi encontrado.{Cores.RESET}")
        print("Por favor, instale o Docker Desktop e certifique-se de que ele esteja")
        print("em execução e que o 'docker-compose' esteja no PATH do seu sistema.")
        sys.exit(1)
    
    try:
        subprocess.run(["docker", "info"], check=True, capture_output=True)
        print(f"{Cores.VERDE}Docker está em execução!{Cores.RESET}")
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        print(f"{Cores.AMARELO}ERRO: O Docker Desktop não parece estar em execução.{Cores.RESET}")
        print("Por favor, inicie o Docker Desktop e tente novamente.")
        sys.exit(1)

def obter_caminho_video():
    """Pede ao usuário o caminho da pasta de vídeos e o valida."""
    imprimir_cabecalho("PASSO 1: PASTA DE VÍDEOS")
    while True:
        print("Por favor, insira o caminho COMPLETO para a sua pasta de vídeos.")
        print(f"{Cores.AMARELO}Exemplo: C:\\Users\\SeuNome\\Videos\\Filmes{Cores.RESET}")
        caminho_str = input("Caminho para os vídeos: ")
        
        if not caminho_str:
            print(f"{Cores.AMARELO}O caminho não pode ser vazio. Tente novamente.{Cores.RESET}\n")
            continue
            
        caminho_path = Path(caminho_str)
        
        if caminho_path.exists() and caminho_path.is_dir():
            print(f"\n{Cores.VERDE}Pasta encontrada!{Cores.RESET}")
            # Retorna o caminho como uma string no formato POSIX (com /) para o YAML
            return caminho_path.as_posix()
        else:
            print(f"\n{Cores.AMARELO}ERRO: O caminho '{caminho_str}' não existe ou não é uma pasta.{Cores.RESET}")
            print("Por favor, verifique o caminho e tente novamente.\n")

def criar_arquivos_projeto(caminho_video):
    """Cria toda a estrutura de pastas e arquivos do projeto."""
    imprimir_cabecalho("PASSO 2: CRIANDO ARQUIVOS DO PROJETO")
    
    # --- Conteúdo dos Arquivos ---

    app_py = """
import os
from flask import Flask, render_template, send_from_directory

app = Flask(__name__)

VIDEO_DIR = "/media/videos"

@app.route('/')
def index():
    videos = []
    supported_formats = ('.mp4', '.webm', '.ogg', '.mov')
    if os.path.exists(VIDEO_DIR):
        for filename in sorted(os.listdir(VIDEO_DIR)):
            if filename.lower().endswith(supported_formats):
                videos.append(filename)
    return render_template('index.html', videos=videos)

@app.route('/video/<path:filename>')
def serve_video(filename):
    return send_from_directory(VIDEO_DIR, filename)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
"""

    index_html = """
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reprodutor de Vídeo Minimalista</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='styles.css') }}">
</head>
<body>
    <div class="container">
        <header>
            <h1>Reprodutor de Vídeo</h1>
        </header>
        <main>
            <div class="player-wrapper">
                <video id="video-player" controls autoplay>
                    Seu navegador não suporta a tag de vídeo.
                </video>
            </div>
            <nav class="playlist">
                <h2>Playlist</h2>
                <ul id="playlist-ul">
                    {% for video in videos %}
                        <li><a href="#" class="video-link" data-video-src="{{ url_for('serve_video', filename=video) }}">{{ video | replace('_', ' ') | replace('.mp4', '') }}</a></li>
                    {% else %}
                        <li>Nenhum vídeo encontrado.</li>
                    {% endfor %}
                </ul>
            </nav>
        </main>
    </div>
    <script>
        document.addEventListener('DOMContentLoaded', () => {
            const videoPlayer = document.getElementById('video-player');
            const playlistLinks = document.querySelectorAll('.video-link');
            const playlistItems = document.querySelectorAll('.playlist li');

            function setActiveLink(activeLink) {
                playlistItems.forEach(item => item.classList.remove('active'));
                if (activeLink) {
                    activeLink.parentElement.classList.add('active');
                }
            }

            playlistLinks.forEach(link => {
                link.addEventListener('click', function(e) {
                    e.preventDefault();
                    const videoSrc = this.getAttribute('data-video-src');
                    videoPlayer.src = videoSrc;
                    videoPlayer.play();
                    document.title = this.textContent;
                    setActiveLink(this);
                });
            });

            if (playlistLinks.length > 0) {
                const firstLink = playlistLinks[0];
                videoPlayer.src = firstLink.getAttribute('data-video-src');
                document.title = firstLink.textContent;
                videoPlayer.play();
                setActiveLink(firstLink);
            }

            videoPlayer.addEventListener('ended', () => {
                const currentActive = document.querySelector('.playlist li.active a');
                let nextLink = null;
                for (let i = 0; i < playlistLinks.length; i++) {
                    if (playlistLinks[i] === currentActive) {
                        if (i < playlistLinks.length - 1) {
                            nextLink = playlistLinks[i + 1];
                        }
                        break;
                    }
                }
                if (nextLink) {
                    nextLink.click();
                }
            });
        });
    </script>
</body>
</html>
"""

    styles_css = """
@import url('https://fonts.googleapis.com/css2?family=Roboto:wght@300;400&display=swap');
:root {
    --bg-color: #121212; --primary-text-color: #e0e0e0; --secondary-text-color: #b3b3b3;
    --surface-color: #1e1e1e; --surface-hover-color: #282828; --divider-color: #333; --accent-color: #bb86fc;
}
body {
    background-color: var(--bg-color); color: var(--primary-text-color); font-family: 'Roboto', sans-serif;
    margin: 0; padding: clamp(1rem, 5vw, 3rem); display: flex; justify-content: center;
}
.container { width: 100%; max-width: 1200px; }
header h1 { font-weight: 300; font-size: 2rem; border-bottom: 1px solid var(--divider-color); padding-bottom: 1rem; margin-bottom: 2rem; }
main { display: grid; grid-template-columns: 1fr; gap: 2rem; }
@media (min-width: 900px) { main { grid-template-columns: 3fr 1fr; } }
.player-wrapper { background-color: #000; border-radius: 8px; overflow: hidden; min-height: 300px; }
video { width: 100%; height: auto; display: block; }
.playlist h2 { font-weight: 400; font-size: 1.5rem; padding-bottom: 0.5rem; margin-top: 0; }
.playlist ul { list-style: none; padding: 0; margin: 0; max-height: 60vh; overflow-y: auto; }
.playlist li a {
    display: block; padding: 12px 15px; text-decoration: none; color: var(--secondary-text-color);
    background-color: var(--surface-color); margin-bottom: 8px; border-radius: 5px; border-left: 4px solid transparent;
    transition: background-color 0.2s ease, color 0.2s ease;
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}
.playlist li a:hover { background-color: var(--surface-hover-color); color: var(--primary-text-color); }
.playlist li.active a {
    color: var(--primary-text-color); font-weight: bold;
    border-left: 4px solid var(--accent-color); background-color: var(--surface-hover-color);
}
"""

    dockerfile_app = """
FROM python:3.9-slim
WORKDIR /app
COPY ./ /app
RUN pip install --no-cache-dir Flask
RUN mkdir -p /media/videos
EXPOSE 5000
CMD ["python", "app.py"]
"""

    dockerfile_tor = """
FROM debian:bullseye-slim
RUN apt-get update && apt-get install -y tor && rm -rf /var/lib/apt/lists/*
COPY torrc /etc/tor/torrc
RUN mkdir -p /var/lib/tor/hidden_service \\
    && chown -R debian-tor:debian-tor /var/lib/tor/hidden_service \\
    && chmod 700 /var/lib/tor/hidden_service
VOLUME /var/lib/tor/hidden_service
USER debian-tor
CMD ["tor"]
"""

    torrc = """
Log notice stdout
HiddenServiceDir /var/lib/tor/hidden_service/
HiddenServicePort 80 web:5000
"""

    # Usando f-string para inserir o caminho do vídeo dinamicamente
    docker_compose_yml = f"""
services:
  web:
    build: .
    container_name: video_player_web
    restart: unless-stopped
    volumes:
      - "{caminho_video}:/media/videos:ro"

  tor:
    build: ./tor
    container_name: video_player_tor
    restart: unless-stopped
    depends_on:
      - web
    volumes:
      - tor_data:/var/lib/tor/hidden_service/

volumes:
  tor_data:
"""

    # Dicionário de arquivos para criar
    arquivos = {
        "app.py": app_py,
        "templates/index.html": index_html,
        "static/styles.css": styles_css,
        "Dockerfile": dockerfile_app,
        "tor/torrc": torrc,
        "tor/Dockerfile": dockerfile_tor,
        "docker-compose.yml": docker_compose_yml,
    }
    
    print("Criando a estrutura de pastas e arquivos do projeto...")
    for caminho, conteudo in arquivos.items():
        path_obj = Path(caminho)
        # Cria as pastas pais se não existirem
        path_obj.parent.mkdir(parents=True, exist_ok=True)
        # Escreve o conteúdo no arquivo
        path_obj.write_text(conteudo.strip(), encoding='utf-8')
        print(f"  - {caminho} ... {Cores.VERDE}OK{Cores.RESET}")
    
    print(f"\n{Cores.VERDE}Todos os arquivos foram criados com sucesso!{Cores.RESET}")
    input("\nPressione Enter para iniciar o servidor...")

def iniciar_servidor():
    """Executa os comandos do Docker Compose para iniciar o servidor."""
    imprimir_cabecalho("PASSO 3: INICIANDO SERVIDOR")
    
    print("Parando quaisquer versões antigas dos contêineres...")
    subprocess.run(["docker-compose", "down", "-v"], capture_output=True)

    print(f"{Cores.AMARELO}Construindo e iniciando os contêineres... Isso pode levar alguns minutos na primeira vez.{Cores.RESET}")
    try:
        subprocess.run(["docker-compose", "up", "--build", "-d"], check=True)
    except subprocess.CalledProcessError as e:
        print(f"\n{Cores.AMARELO}ERRO: Falha ao iniciar os contêineres.{Cores.RESET}")
        print("Verifique os logs do Docker para mais detalhes.")
        sys.exit(1)
    
    print(f"\n{Cores.VERDE}Contêineres iniciados!{Cores.RESET}")
    print(f"{Cores.AMARELO}Aguardando o Tor iniciar e gerar o endereço (30 segundos)...{Cores.RESET}")
    
    for i in range(30, 0, -1):
        print(f"Aguarde... {i}", end='\r')
        time.sleep(1)
    
    print("\nBuscando seu endereço .onion...")
    
    try:
        # Tenta buscar o endereço algumas vezes
        for tentativa in range(3):
            resultado = subprocess.run(
                ["docker-compose", "exec", "tor", "cat", "/var/lib/tor/hidden_service/hostname"],
                capture_output=True, text=True, check=True
            )
            onion_address = resultado.stdout.strip()
            if onion_address:
                imprimir_cabecalho("SEU SERVIDOR ESTÁ NO AR!")
                print("Copie o endereço abaixo e cole no seu Tor Browser:\n")
                print(f"{Cores.VERDE}{onion_address}{Cores.RESET}\n")
                print(f"{Cores.AMARELO}Para parar o servidor, pressione CTRL+C nesta janela ou execute 'docker-compose down' neste diretório.{Cores.RESET}")
                return
            time.sleep(5) # Espera mais um pouco se falhar
    except (subprocess.CalledProcessError, FileNotFoundError):
        print(f"\n{Cores.AMARELO}ERRO: Não foi possível obter o endereço .onion.{Cores.RESET}")
        print("O contêiner do Tor pode ter falhado ao iniciar. Verifique os logs com o comando:")
        print("'docker-compose logs tor'")

def main():
    """Função principal que orquestra o script."""
    # Habilita suporte a cores ANSI no Windows
    if os.name == 'nt':
        os.system("")

    try:
        verificar_docker()
        caminho_video_str = obter_caminho_video()
        criar_arquivos_projeto(caminho_video_str)
        iniciar_servidor()
    except KeyboardInterrupt:
        print(f"\n\n{Cores.AMARELO}Operação cancelada pelo usuário. Parando os servidores...{Cores.RESET}")
        subprocess.run(["docker-compose", "down", "-v"], capture_output=True)
        print("Servidores parados.")
    except Exception as e:
        print(f"\n{Cores.AMARELO}Ocorreu um erro inesperado: {e}{Cores.RESET}")

if __name__ == "__main__":
    main()