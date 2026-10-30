# InfraDev Remote (app)

Fork do [RustDesk](https://github.com/rustdesk/rustdesk) (AGPL-3.0) com o servidor da InfraDev embutido.
Servidor e documentação: [infradev-solutions/infradev-remote](https://github.com/infradev-solutions/infradev-remote).

## O que muda em relação ao RustDesk oficial

- Servidor de ID e relay: `remote.infradevsolutions.com.br`
- Chave pública do servidor embutida (o app só conversa com o servidor da InfraDev)
- Servidor de API (login e catálogo de endereços): `http://remote.infradevsolutions.com.br:21114`
- Ícones e logos da InfraDev (Windows, macOS, Linux, Android e dentro do app)
- Nome **InfraDev Remote** no Android, no menu do Linux, nas propriedades do .exe e nos textos do app

O nome interno continua "RustDesk" (serviço do Windows, pastas de configuração, link `rustdesk://`).
Trocar isso exigiria renomear serviços e instaladores em todas as plataformas, com risco de quebrar
instalação e atualização.

## Trocar o ícone

Coloque um PNG de 1024x1024 com fundo transparente em `source/icone.png` e rode
`python3 infradev/gerar-icones.py` (precisa do Pillow). Os arquivos gerados ficam em `assets/`.

Servidor, chave e nome ficam em [branding.env](branding.env). O script [apply-branding.sh](apply-branding.sh) aplica as
trocas no código durante o build, então o resto do fork continua igual ao RustDesk e fica fácil
puxar atualizações (botão **Sync fork** no GitHub).

## Gerar os instaladores

1. Aba **Actions** → se pedir, clique em **I understand my workflows, go ahead and enable them**.
2. Escolha **InfraDev Remote - gerar instaladores** → **Run workflow**.
3. Ao terminar (pode levar mais de uma hora), os arquivos ficam em **Releases → infradev**.

Os instaladores não são assinados digitalmente: o Windows SmartScreen e o macOS vão avisar na
primeira execução. iOS não é gerado (exige conta de desenvolvedor Apple).
