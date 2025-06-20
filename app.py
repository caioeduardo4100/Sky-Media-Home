import os
from flask import Flask, render_template, send_from_directory, url_for

app = Flask(__name__)

# Este é o caminho DENTRO do contêiner Docker onde os vídeos estarão.
# O Docker irá linkar uma pasta do seu computador a este caminho.
VIDEO_DIR = "/media/videos"

@app.route('/')
def index():
    """
    Escaneia o diretório de vídeos em busca de arquivos compatíveis
    e renderiza a página principal com a lista de vídeos.
    """
    videos = []
    supported_formats = ('.mp4', '.webm', '.ogg', '.mov')
    if os.path.exists(VIDEO_DIR):
        # Classifica os arquivos para uma ordem consistente
        for filename in sorted(os.listdir(VIDEO_DIR)):
            if filename.lower().endswith(supported_formats):
                videos.append(filename)
    return render_template('index.html', videos=videos)

@app.route('/video/<path:filename>')
def serve_video(filename):
    """
    Serve o arquivo de vídeo solicitado a partir do diretório de vídeos.
    """
    return send_from_directory(VIDEO_DIR, filename)

if __name__ == '__main__':
    # Executa o servidor na rede local (0.0.0.0) para ser acessível
    # de fora do contêiner Docker. O modo debug é desativado para produção.
    app.run(host='0.0.0.0', port=5000)