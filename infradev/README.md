# InfraDev Remote (app)

Fork do [RustDesk](https://github.com/rustdesk/rustdesk) (AGPL-3.0) com o servidor da InfraDev embutido.
Servidor e documentação: [infradev-solutions/infradev-remote](https://github.com/infradev-solutions/infradev-remote).

## O que muda em relação ao RustDesk oficial

- Servidor de ID e relay: `remote.infradevsolutions.com.br`
- Chave pública do servidor embutida (o app só conversa com o servidor da InfraDev)
- Servidor de API (login e catálogo de endereços): `http://remote.infradevsolutions.com.br:21114`
- Ícones e logos da InfraDev (Windows, macOS, Linux, Android e dentro do app)
- Nome **InfraDev Remote** no Android, no menu do Linux, nas propriedades do .exe e nos textos do app
- Links do site apontam para infradevsolutions.com.br, e o de download aponta para a release deste fork
- O app não procura atualização do RustDesk oficial, que trocaria o app por uma versão sem a marca e sem o servidor
- Instaladores publicados como `infradev-remote-*` (o build gera `rustdesk-*`, e um job no final renomeia)

No Windows o nome interno é "InfraDevRemote" (`INFRADEV_INTERNAL_NAME` em `branding.env`): pasta `C:\Program Files\InfraDevRemote`, atalhos, serviço, `.exe` instalado, `%AppData%\InfraDevRemote` e o MSI.
Nos outros sistemas o nome interno continua "RustDesk" por enquanto.

## Trocar o ícone

Coloque um PNG de 1024x1024 com fundo transparente em `source/icone.png` e rode
`python3 infradev/gerar-icones.py` (precisa do Pillow). Os arquivos gerados ficam em `assets/`.

Servidor, chave e nome ficam em [branding.env](branding.env). O script [apply-branding.sh](apply-branding.sh) aplica as
trocas no código durante o build, então o resto do fork continua igual ao RustDesk e fica fácil
puxar atualizações (botão **Sync fork** no GitHub).

## Gerar os instaladores

1. Aba **Actions** → se pedir, clique em **I understand my workflows, go ahead and enable them**.
2. Escolha **InfraDev Remote - gerar instaladores** → **Run workflow**.
3. Ao terminar (pode levar mais de uma hora), os arquivos ficam em **Releases → infradev** deste fork
   e, se o secret `INFRADEV_REMOTE_TOKEN` estiver configurado, também em
   [infradev-remote → Releases → instaladores](https://github.com/infradev-solutions/infradev-remote/releases/tag/instaladores).

Use sempre **Run workflow**. O **Re-run** de uma execução antiga usa o código daquela data.

### Configurar o INFRADEV_REMOTE_TOKEN (uma vez só)

1. GitHub → foto do perfil → **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**.
2. *Repository access*: **Only select repositories** → `infradev-remote`.
3. *Permissions → Repository permissions → Contents*: **Read and write**. Validade: a maior possível.
4. Copie o token. Neste fork: **Settings → Secrets and variables → Actions → New repository secret**,
   nome `INFRADEV_REMOTE_TOKEN`, cole o token.

Os instaladores não são assinados digitalmente: o Windows SmartScreen e o macOS vão avisar na
primeira execução. iOS não é gerado (exige conta de desenvolvedor Apple).
