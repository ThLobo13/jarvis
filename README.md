J.A.R.V.I.S. — Assistente de voz para CMD / PowerShell
Assistente estilo Jarvis do Homem de Ferro: você fala, ele entende, pensa com uma IA que roda no seu próprio PC, abre seus programas e responde em voz alta, em 7 idiomas (Português, English, Español, Français, Deutsch, Italiano, 日本語).
Como funciona
Parte	Tecnologia
Ouvido (voz → texto)	`SpeechRecognition` + Google Speech (gratuito, precisa de internet)
Cérebro	Ollama (modelo local gratuito, sem chave). Opcional: Claude via API
Comandos rápidos	Abrir programas, pesquisar, YouTube, trocar idioma e sair funcionam sem IA, na hora
Voz (texto → voz)	`edge-tts` (vozes neurais, precisa de internet). Se falhar, usa `pyttsx3` offline
Ativação	Palavra "Jarvis" (depois de responder, fica ouvindo 25 s sem precisar repetir)
Instalação automática (recomendada, serve para outros computadores)
O `install.ps1` instala tudo sozinho: Python 3.12 (se faltar), Ollama, dependências, o modelo de IA e cria o atalho na Área de Trabalho e o comando `jarvis`. Precisa de internet e do winget (já vem no Windows 10/11 atualizado).
Opção A: levar por pen drive / zip
No PC onde já funciona, na pasta do Jarvis, gere o pacote (sem a pasta `venv`):
```powershell
   Compress-Archive -Path jarvis.py,requirements.txt,jarvis.bat,install.ps1,install.bat,README.md -DestinationPath jarvis.zip -Force
   ```
Copie o `jarvis.zip` para o outro PC e extraia.
Dê dois cliques em `install.bat` (ou, no terminal da pasta: `powershell -ExecutionPolicy Bypass -File .\\install.ps1`).
Opção B: por um comando, direto da internet
Suba os 6 arquivos para um repositório público no GitHub (ou outro lugar que sirva arquivos de texto cru).
No outro PC, abra o PowerShell e rode (troque a URL pela sua):
```powershell
   $env:JARVIS\_BASE\_URL = "https://raw.githubusercontent.com/SEU\_USUARIO/SEU\_REPO/main"
   irm "$env:JARVIS\_BASE\_URL/install.ps1" | iex
   ```
Opções (defina antes de rodar, no PowerShell): `$env:JARVIS\_MODEL = "qwen2.5:3b"` (PC fraco), `$env:JARVIS\_DIR = "D:\\jarvis"` (outra pasta), `$env:JARVIS\_SKIP\_MODEL = "1"` (não baixar o modelo agora).
Ao terminar: abra um terminal novo e digite `jarvis`, ou use o atalho da Área de Trabalho. Se preferir instalar manualmente, siga as seções abaixo.
1. Pré-requisitos
Windows 10/11 com microfone e caixas de som.
Python 3.10, 3.11 ou 3.12 (https://www.python.org/downloads/). Marque "Add python.exe to PATH".
Ollama (https://ollama.com/download): instale e deixe o app aberto (ícone na bandeja).
Um PC com 8 GB de RAM ou mais. Com placa de vídeo é bem mais rápido; sem ela funciona, só mais devagar.
2. Instalação
```powershell
mkdir C:\\jarvis
cd C:\\jarvis
```
Copie para essa pasta `jarvis.py`, `requirements.txt` e `jarvis.bat`. Depois:
```powershell
python -m venv venv
venv\\Scripts\\activate
pip install -r requirements.txt
```
> No PowerShell, se o `activate` for bloqueado: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`
3. Baixar o modelo de IA (uma vez só)
```powershell
ollama pull qwen2.5:7b
```
São ~4,7 GB. O `qwen2.5` entende bem vários idiomas e sabe usar ferramentas. PC mais fraco (pouca RAM, sem placa de vídeo)? Use o menor:
```powershell
ollama pull qwen2.5:3b
setx JARVIS\_MODEL "qwen2.5:3b"
```
(feche e abra o terminal depois do `setx`). Se o seu PC for forte, `qwen2.5:14b` fica ainda mais esperto.
4. Rodando
```powershell
cd C:\\jarvis
venv\\Scripts\\activate
python jarvis.py
```
Ou dê dois cliques no `jarvis.bat`. Não precisa de nenhuma chave de API.
Opções:
Comando	O que faz
`python jarvis.py`	Modo voz (diga "Jarvis" + pedido)
`python jarvis.py --text`	Modo texto, útil para testar sem microfone
`python jarvis.py --no-wake`	Escuta sempre, sem a palavra "Jarvis"
`python jarvis.py --lang en`	Já começa em inglês
`python jarvis.py --list-mics`	Lista microfones
`python jarvis.py --mic 2`	Usa o microfone de índice 2
Variáveis opcionais (`setx NOME "valor"`): `JARVIS\_USER` (como ele te chama), `JARVIS\_LANG` (`pt`, `en`, `es`, `fr`, `de`, `it`, `ja`), `JARVIS\_MODEL` (modelo do Ollama).
5. O que dizer
Comandos rápidos (instantâneos, sem IA):
"Jarvis, abre o Discord" / "abre o Chrome" / "abre a calculadora" (qualquer programa do Menu Iniciar)
"Jarvis, abre o YouTube" / "abre o Gmail"
"Jarvis, pesquisa receita de bolo de cenoura"
"Jarvis, toca Queen no YouTube"
"Jarvis, speak English" · "habla español" · "parle français" · "sprich Deutsch" · "parla italiano" · "日本語で話して" · "fale português"
"Jarvis, tchau" / "desliga"
Conversa e tarefas (usa o modelo local):
"Que horas são?" · "Me explica o que é um buraco negro" · "Anota: comprar leite amanhã" · "Quanto espaço livre tenho no disco?"
Os modelos locais são menos espertos que o Claude. Para frases complicadas, fale de forma direta e curta.
6. Programas
Ao iniciar, o Jarvis lê todos os programas do Menu Iniciar (tradicionais e da Microsoft Store) e mostra quantos achou. Diga o nome como aparece no Menu Iniciar (pode ser aproximado). Instalou algo novo? Reinicie o Jarvis. Programas portáteis que não aparecem no Menu Iniciar: adicione ao dicionário `APPS` em `jarvis.py`:
```python
APPS = {
    ...
    "meu\_programa": r"C:\\Pasta\\meu\_programa.exe",
}
```
7. Atalho global: digitar `jarvis` em qualquer terminal
Coloque `C:\\jarvis` no PATH: Iniciar → "Editar as variáveis de ambiente do sistema" → Variáveis de Ambiente → Path (usuário) → Novo → `C:\\jarvis`.
Abra um terminal novo e digite `jarvis`.
PowerShell, alternativa: `notepad $PROFILE` e adicione
```powershell
function jarvis { \& "C:\\jarvis\\jarvis.bat" @args }
```
Para abrir junto com o Windows: `Win + R` → `shell:startup` → coloque um atalho do `jarvis.bat`.
8. Personalizando
Novos comandos rápidos: edite `quick\_command()` e as listas/expressões logo acima dela.
Nova ferramenta para a IA (volume, e-mail, luzes...): acrescente em `TOOLS` e trate em `run\_tool`.
Voz: troque `voice` em `LANGS` (`edge-tts --list-voices` lista todas).
Personalidade: edite `system\_prompt()`.
9. Usar o Claude em vez do modelo local (opcional)
Só se você tiver créditos na API da Anthropic (separados da assinatura do Claude.ai):
```powershell
pip install anthropic
setx JARVIS\_BACKEND "claude"
setx ANTHROPIC\_API\_KEY "sua-chave"
```
Para voltar ao modo gratuito, apague `JARVIS\_BACKEND` (ou use `setx JARVIS\_BACKEND "ollama"`).
10. Problemas comuns
Problema	Solução
"Não consegui falar com o Ollama"	Instale o Ollama e deixe o app aberto na bandeja do Windows
"O modelo ainda não foi baixado"	Rode `ollama pull qwen2.5:7b` (ou o modelo que você escolheu)
Respostas lentas	Use `qwen2.5:3b` (veja o passo 3). A primeira resposta sempre demora mais, porque carrega o modelo
A IA erra ou não executa uma ação	Use os comandos rápidos da seção 5 (são exatos) ou teste um modelo maior
`pip install PyAudio` falha	Use Python 3.10–3.12. Se persistir: `pip install pipwin` e `pipwin install pyaudio`
Microfone não abre	`--list-mics` e `--mic N`; confira Configurações → Privacidade → Microfone
Ele não entende "Jarvis"	Fale mais pausado; acrescente variações em `WAKE\_WORDS` (veja o "ouvi:" no terminal)
Sem som	Confira a saída de áudio do Windows; o `pyttsx3` entra como plano B
Caracteres estranhos	Use o Windows Terminal ou `chcp 65001` (o `jarvis.bat` já faz)
Não abre um programa	Fale o nome como aparece no Menu Iniciar, ou adicione ao `APPS`
11. Segurança e privacidade
Só abre programas do Menu Iniciar (ou da lista `APPS`) e links `http(s)`. Não executa comandos arbitrários.
O cérebro roda no seu PC: o que você conversa com a IA não sai dele. Só o áudio vai ao Google (para virar texto) e o texto vai ao serviço de voz da Microsoft (para falar).
