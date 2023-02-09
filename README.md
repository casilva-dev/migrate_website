![Migrate Website](https://cdn-icons-png.flaticon.com/128/4403/4403110.png)
# MigrateWebsite

[![Shell Script](https://img.shields.io/badge/Shell-Script-black.svg?logo=PowerShell&logoColor=white)](https://www.gnu.org/software/bash/)
[![PHP 5.6](https://img.shields.io/badge/PHP-5.6+-blue.svg)](https://www.php.net/)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-green.svg)](https://www.gnu.org/licenses/gpl-3.0)

O projeto Migrate Website tem como objetivo migrar arquivos e banco de dados de website(s) do servidor de origem para um servidor de destino. Ele utiliza a linguagem de script bash e as seguintes ferramentas: wget, jq, ftp, mysql-client e zip. Antes da migração, o script verifica se as dependências estão instaladas e, caso não estejam, instala-as automaticamente.

## Como usar

Baixe o MigrateWebsite no repositório Git:

```bash
git clone https://gitlab.com/cesarasilva/migrate_website.git
```

Entre na pasta do projeto, copie o arquivo "configs.json.default" para um novo arquivo chamado "configs.json".

```bash
cd migrate_website/
cp configs.json.default configs.json
```

Edite o arquivo "configs.json" e adicione as configurações do servidor FTP e o banco de dados MySQL:

```json
[
    {   
        "filename_db": "database.php",
        "url_http": "www.domain2.com",
        "ftp": {
            "src": {
                "host": "ftp.domain1.com",
                "path": "public_html",
                "user": "ftp_user1",
                "pass": "ftp_password1"
            },
            "dst": {
                "host": "ftp.domain2.com",
                "path": "www",
                "user": "ftp_user2",
                "pass": "ftp_password2"
            }
        },
        "db": {
            "src": {
                "host": "mysql.domain1.com",
                "dbname": "domain1_database",
                "user": "domain1_user",
                "pass": "domain1_password"
            },
            "dst": {
                "host": "mysql.domain2.com",
                "dbname": "domain2_database",
                "user": "domain2_user",
                "pass": "domain2_password"
            }
        }
    },
    ...
]
```

O script pode ser utilizado de duas formas diferentes:

1. **Docker**

    Inicie o Docker, caso não esteja rodando, e execute o seguinte comando:

    ```bash
    docker build -t migrate_website .
    docker run -it migrate_website
    ```

    O Docker irá iniciar o container, instalar os pacotes de dependências e executar o script.

2. **Manual**

    Para rodar o script manualmente no terminal do seu computador, basta conceder a permissão de execução no script e executá-lo:

    ```bash
    chmod +x migrate_website.sh
    ./migrate_website.sh
    ```

## Contribuição

Nós encorajamos a contribuição de todos! Aqui estão as instruções para começar:

1. Faça um fork do projeto.
2. Crie sua branch para a nova funcionalidade (`git checkout -b nova-funcionalidade`).
3. Commit suas mudanças (`git commit -am 'Adicionando nova funcionalidade'`).
4. Empurre a branch (`git push origin nova-funcionalidade`).
5. Crie um novo Pull Request para o projeto principal.

Por favor, verifique antes de enviar seu pull request que o código segue as diretrizes de codificação do projeto, incluindo os padrões de formatação e testes automatizados.

## Licença

Este projeto está licenciado sob a licença [GNU General Public License v3.0](https://www.gnu.org/licenses/gpl-3.0.en.html).

## Créditos

Gostaria de agradecer à [OpenAI](https://openai.com) pela utilização de seu modelo [ChatGPT](https://chat.openai.com), que me ajudou imensamente durante o desenvolvimento deste projeto.