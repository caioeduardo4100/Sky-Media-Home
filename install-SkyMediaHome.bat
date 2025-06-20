@echo off
title Servidor de Video Pessoal via Tor - Instalador

:: Bloco de Cores (ANSI Escape Codes)
:: Gera o caractere de escape (ESC) para ser usado nas cores
for /f %%a in ('"prompt $E & for %%b in (1) do rem"') do set "ESC=%%a"
set "verde=%ESC%[92m"
set "amarelo=%ESC%[93m"
set "ciano=%ESC%[96m"
set "reset=%ESC%[0m"

:INICIO
cls
echo.
echo %ciano%===========================================================%reset%
echo %ciano%      INSTALADOR DO REPRODUTOR DE VIDEO PESSOAL VIA TOR      %reset%
echo %ciano%===========================================================%reset%
echo.
echo Este script ira configurar um servidor de video que voce podera
echo acessar de qualquer lugar do mundo atraves da rede Tor.
echo.
echo %amarelo%Requisito: Docker Desktop deve estar instalado e em execucao.%reset%
echo.
pause
echo.

:PEDIR_CAMINHO
cls
echo.
echo %ciano%===========================================================%reset%
echo %ciano%                   PASSO 1: PASTA DE VIDEOS                  %reset%
echo %ciano%===========================================================%reset%
echo.
echo Por favor, insira o caminho COMPLETO para a sua pasta de
echo filmes, series ou videos.
echo.
echo %amarelo%Exemplo para Windows: C:\Users\Joao\Videos\Filmes%reset%
echo.
set "VIDEO_PATH="
set /p "VIDEO_PATH=Caminho para os videos: "

if not defined VIDEO_PATH (
    echo.
    echo %amarelo%O caminho nao pode ser vazio. Pressione qualquer tecla para tentar novamente.%reset%
    pause >nul
    goto PEDIR_CAMINHO
)

if not exist "%VIDEO_PATH%" (
    echo.
    echo %amarelo%ERRO: A pasta "%VIDEO_PATH%" nao foi encontrada.%reset%
    echo %amarelo%Pressione qualquer tecla para tentar novamente.%reset%
    pause >nul
    goto PEDIR_CAMINHO
)

echo.
echo Otimo! A pasta de videos foi definida como:
echo %VIDEO_PATH%
echo.
pause
goto CRIAR_ARQUIVOS

:CRIAR_ARQUIVOS
cls
echo.
echo %ciano%===========================================================%reset%
echo %ciano%             PASSO 2: CRIANDO ARQUIVOS DO PROJETO            %reset%
echo %ciano%===========================================================%reset%
echo.
echo Criando a estrutura de diretorios...
if not exist "templates" mkdir templates
if not exist "static" mkdir static
if not exist "tor" mkdir tor
echo.

rem --- Cria app.py ---
echo Criando app.py...
(
    echo import os
    echo from flask import Flask, render_template, send_from_directory, url_for
    echo.
    echo app = Flask(__name__)
    echo.
    echo VIDEO_DIR = "/media/videos"
    echo.
    echo @app.route('/')
    echo def index():
    echo     videos = []
    echo     supported_formats = ('.mp4', '.webm', '.ogg', '.mov')
    echo     if os.path.exists(VIDEO_DIR):
    echo         for filename in sorted(os.listdir(VIDEO_DIR)):
    echo             if filename.lower().endswith(supported_formats):
    echo                 videos.append(filename)
    echo     return render_template('index.html', videos=videos)
    echo.
    echo @app.route('/video/^<path:filename^>')
    echo def serve_video(filename):
    echo     return send_from_directory(VIDEO_DIR, filename)
    echo.
    echo if __name__ == '__main__':
    echo     app.run(host='0.0.0.0', port=5000)
) > app.py

rem --- Cria templates/index.html ---
echo Criando templates/index.html...
(
    echo ^<!DOCTYPE html^>
    echo ^<html lang="pt-BR"^>
    echo ^<head^>
    echo     ^<meta charset="UTF-8"^>
    echo     ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^>
    echo     ^<title^>Reprodutor de Video Minimalista^</title^>
    echo     ^<link rel="stylesheet" href="{{ url_for('static', filename='styles.css') }}"^>
    echo ^</head^>
    echo ^<body^>
    echo     ^<div class="container"^>
    echo         ^<header^>
    echo             ^<h1^>Reprodutor de Video^</h1^>
    echo         ^</header^>
    echo         ^<main^>
    echo             ^<div class="player-wrapper"^>
    echo                 ^<video id="video-player" controls autoplay^>
    echo                     Seu navegador nao suporta a tag de video.
    echo                 ^</video^>
    echo             ^</div^>
    echo             ^<nav class="playlist"^>
    echo                 ^<h2^>Playlist^</h2^>
    echo                 ^<ul id="playlist-ul"^>
    echo                     {%% for video in videos %%}
    echo                         ^<li^>^<a href="#" class="video-link" data-video-src="{{ url_for('serve_video', filename=video) }}"^>{{ video ^| replace('_', ' ') ^| replace('.mp4', '') }}^</a^>^</li^>
    echo                     {%% else %%}
    echo                         ^<li^>Nenhum video encontrado.^</li^>
    echo                     {%% endfor %%}
    echo                 ^</ul^>
    echo             ^</nav^>
    echo         ^</main^>
    echo     ^</div^>
    echo     ^<script^>
    echo         document.addEventListener('DOMContentLoaded', () =^> {
    echo             const videoPlayer = document.getElementById('video-player');
    echo             const playlistLinks = document.querySelectorAll('.video-link');
    echo             const playlistItems = document.querySelectorAll('.playlist li');
    echo.
    echo             function setActiveLink(activeLink) {
    echo                 playlistItems.forEach(item =^> item.classList.remove('active'));
    echo                 if (activeLink) {
    echo                     activeLink.parentElement.classList.add('active');
    echo                 }
    echo             }
    echo.
    echo             playlistLinks.forEach(link =^> {
    echo                 link.addEventListener('click', function(e) {
    echo                     e.preventDefault();
    echo                     const videoSrc = this.getAttribute('data-video-src');
    echo                     videoPlayer.src = videoSrc;
    echo                     videoPlayer.play();
    echo                     document.title = this.textContent;
    echo                     setActiveLink(this);
    echo                 });
    echo             });
    echo.
    echo             if (playlistLinks.length ^> 0) {
    echo                 const firstLink = playlistLinks[0];
    echo                 videoPlayer.src = firstLink.getAttribute('data-video-src');
    echo                 document.title = firstLink.textContent;
    echo                 videoPlayer.play();
    echo                 setActiveLink(firstLink);
    echo             }
    echo.
    echo             videoPlayer.addEventListener('ended', () =^> {
    echo                 const currentActive = document.querySelector('.playlist li.active a');
    echo                 let nextLink = null;
    echo                 for (let i = 0; i ^< playlistLinks.length; i++) {
    echo                     if (playlistLinks[i] === currentActive) {
    echo                         if (i ^< playlistLinks.length - 1) {
    echo                             nextLink = playlistLinks[i + 1];
    echo                         }
    echo                         break;
    echo                     }
    echo                 }
    echo                 if (nextLink) {
    echo                     nextLink.click();
    echo                 }
    echo             });
    echo         });
    echo     ^</script^>
    echo ^</body^>
    echo ^</html^>
) > templates\index.html

rem --- Cria static/styles.css ---
echo Criando static/styles.css...
(
    echo @import url('https://fonts.googleapis.com/css2?family=Roboto:wght@300;400^&display=swap');
    echo.
    echo :root {
    echo     --bg-color: #121212;
    echo     --primary-text-color: #e0e0e0;
    echo     --secondary-text-color: #b3b3b3;
    echo     --surface-color: #1e1e1e;
    echo     --surface-hover-color: #282828;
    echo     --divider-color: #333;
    echo     --accent-color: #bb86fc;
    echo }
    echo.
    echo body {
    echo     background-color: var(--bg-color);
    echo     color: var(--primary-text-color);
    echo     font-family: 'Roboto', -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
    echo     margin: 0;
    echo     padding: clamp(1rem, 5vw, 3rem);
    echo     display: flex;
    echo     justify-content: center;
    echo }
    echo.
    echo .container {
    echo     width: 100%%;
    echo     max-width: 1200px;
    echo }
    echo.
    echo header h1 {
    echo     font-weight: 300;
    echo     font-size: 2rem;
    echo     border-bottom: 1px solid var(--divider-color);
    echo     padding-bottom: 1rem;
    echo     margin-bottom: 2rem;
    echo }
    echo.
    echo main {
    echo     display: grid;
    echo     grid-template-columns: 1fr;
    echo     gap: 2rem;
    echo }
    echo.
    echo @media (min-width: 900px) {
    echo     main {
    echo         grid-template-columns: 3fr 1fr;
    echo     }
    echo }
    echo.
    echo .player-wrapper {
    echo     background-color: #000;
    echo     border-radius: 8px;
    echo     overflow: hidden;
    echo     min-height: 300px;
    echo }
    echo.
    echo video {
    echo     width: 100%%;
    echo     height: auto;
    echo     display: block;
    echo }
    echo.
    echo .playlist h2 {
    echo     font-weight: 400;
    echo     font-size: 1.5rem;
    echo     padding-bottom: 0.5rem;
    echo     margin-top: 0;
    echo }
    echo.
    echo .playlist ul {
    echo     list-style: none;
    echo     padding: 0;
    echo     margin: 0;
    echo     max-height: 60vh;
    echo     overflow-y: auto;
    echo }
    echo.
    echo .playlist li a {
    echo     display: block;
    echo     padding: 12px 15px;
    echo     text-decoration: none;
    echo     color: var(--secondary-text-color);
    echo     background-color: var(--surface-color);
    echo     margin-bottom: 8px;
    echo     border-radius: 5px;
    echo     border-left: 4px solid transparent;
    echo     transition: background-color 0.2s ease, color 0.2s ease;
    echo     white-space: nowrap;
    echo     overflow: hidden;
    echo     text-overflow: ellipsis;
    echo }
    echo.
    echo .playlist li a:hover {
    echo     background-color: var(--surface-hover-color);
    echo     color: var(--primary-text-color);
    echo }
    echo.
    echo .playlist li.active a {
    echo     color: var(--primary-text-color);
    echo     font-weight: bold;
    echo     border-left: 4px solid var(--accent-color);
    echo     background-color: var(--surface-hover-color);
    echo }
) > static\styles.css

rem --- Cria Dockerfile da app ---
echo Criando Dockerfile principal...
(
    echo FROM python:3.9-slim
    echo WORKDIR /app
    echo COPY ./ /app
    echo RUN pip install --no-cache-dir Flask
    echo RUN mkdir -p /media/videos
    echo EXPOSE 5000
    echo CMD ["python", "app.py"]
) > Dockerfile

rem --- Cria tor/torrc ---
echo Criando tor/torrc...
(
    echo Log notice stdout
    echo HiddenServiceDir /var/lib/tor/hidden_service/
    echo HiddenServicePort 80 web:5000
) > tor\torrc

rem --- Cria tor/Dockerfile ---
echo Criando tor/Dockerfile...
(
    echo FROM debian:bullseye-slim
    echo RUN apt-get update ^&^& apt-get install -y tor ^&^& rm -rf /var/lib/apt/lists/*
    echo COPY torrc /etc/tor/torrc
    echo RUN mkdir -p /var/lib/tor/hidden_service \
    echo     ^&^& chown -R debian-tor:debian-tor /var/lib/tor/hidden_service \
    echo     ^&^& chmod 700 /var/lib/tor/hidden_service
    echo VOLUME /var/lib/tor/hidden_service
    echo USER debian-tor
    echo CMD ["tor"]
) > tor\Dockerfile

rem --- Cria docker-compose.yml ---
echo Criando docker-compose.yml com o seu caminho de video...
(
    echo services:
    echo   web:
    echo     build: .
    echo     container_name: video_player_web
    echo     restart: unless-stopped
    echo     volumes:
    echo       - "%VIDEO_PATH%:/media/videos:ro"
    echo.
    echo   tor:
    echo     build: ./tor
    echo     container_name: video_player_tor
    echo     restart: unless-stopped
    echo     depends_on:
    echo       - web
    echo     volumes:
    echo       - tor_data:/var/lib/tor/hidden_service/
    echo.
    echo volumes:
    echo   tor_data:
) > docker-compose.yml

echo.
echo %verde%Todos os arquivos foram criados com sucesso!%reset%
echo.
pause
goto INICIAR_DOCKER

:INICIAR_DOCKER
cls
echo.
echo %ciano%===========================================================%reset%
echo %ciano%                 PASSO 3: INICIANDO SERVIDOR                 %reset%
echo %ciano%===========================================================%reset%
echo.
echo Parando quaisquer versoes antigas dos contêineres...
docker-compose down -v >nul 2>nul
echo.
echo Construindo e iniciando os novos contêineres.
echo %amarelo%Isso pode levar alguns minutos na primeira vez...%reset%
echo.
docker-compose up --build -d
echo.
echo %amarelo%Aguardando o Tor iniciar e gerar o endereco (30 segundos)...%reset%
timeout /t 30 /nobreak >nul
echo.
echo Buscando seu endereco .onion...
echo.

rem --- Pega o endereço .onion e o exibe em verde ---
for /f "delims=" %%i in ('docker-compose exec tor cat /var/lib/tor/hidden_service/hostname') do set "ONION_ADDRESS=%%i"

if defined ONION_ADDRESS (
    echo %verde%===========================================================%reset%
    echo %verde%                 SEU SERVIDOR ESTA NO AR!                  %reset%
    echo %verde%===========================================================%reset%
    echo.
    echo Copie o endereco abaixo e cole no seu Tor Browser:
    echo.
    echo %verde%%ONION_ADDRESS%%reset%
    echo.
    echo %amarelo%Nao feche esta janela se quiser manter o servidor rodando.%reset%
    echo %amarelo%Para parar o servidor, feche esta janela ou execute 'docker-compose down' neste diretorio.%reset%
    echo.
) else (
    echo %amarelo%ERRO: Nao foi possivel obter o endereco .onion.%reset%
    echo %amarelo%Verifique os logs com o comando 'docker-compose logs tor'%reset%
)

pause
exit