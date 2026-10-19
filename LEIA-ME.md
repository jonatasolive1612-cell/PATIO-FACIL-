# Pátio Fácil — primeira versão (MVP)

Aplicativo web instalável (PWA) para registrar entradas e saídas, fotos, pesquisar veículos, consultar histórico e exportar CSV.

## Importante antes de usar

- Sem configuração do Supabase, o app abre em **modo demonstração local**. Os dados e fotos ficam somente no navegador/aparelho e não sincronizam. Use apenas dados fictícios nesse modo.
- Para uso real, configure o Supabase e publique o app por HTTPS. O arquivo `supabase-schema.sql` fornece a estrutura inicial e políticas de acesso.
- A leitura automática de placa ainda não está implementada: o botão de placa abre a câmera/seleção de imagem, e o usuário digita ou confirma a placa manualmente.
- Este MVP não implementa fila offline confiável. Como a escolha foi aguardar a internet, use o sistema em rede estável na versão de produção.
- Antes de produção, revise as políticas de segurança com alguém responsável por banco de dados. O esquema é um ponto de partida e não substitui revisão profissional.

## Testar localmente

1. Descompacte a pasta do projeto.
2. Abra um terminal dentro da pasta.
3. Rode `python -m http.server 8080` (ou `npx serve .`).
4. Abra `http://localhost:8080` no navegador.
5. O modo demonstração abre sem login. Teste entrada, fotos, saída, busca, histórico e exportação.
6. No celular, para testar a câmera, publique em HTTPS ou use `localhost` no próprio aparelho. Navegadores exigem contexto seguro para alguns recursos.

## Ativar banco de dados e login (Supabase)

1. Crie um projeto em https://supabase.com/.
2. No SQL Editor, execute o arquivo `supabase-schema.sql`.
3. Em Authentication > Users, crie um usuário para o administrador e outro para o porteiro, com senhas fortes.
4. No SQL Editor, insira um perfil para cada usuário usando os exemplos no fim de `supabase-schema.sql`. Troque os e-mails e nomes pelos reais.
5. Copie a Project URL e a chave publicável/anon do painel do Supabase.
6. No `index.html`, preencha `SUPABASE_URL` e `SUPABASE_ANON_KEY`. **Nunca coloque a service_role key no navegador.**
7. Publique os arquivos em uma hospedagem estática HTTPS (por exemplo, Vercel ou Netlify).
8. Entre com o usuário criado e teste com dados fictícios primeiro.

## Publicar na Vercel (caminho simples)

1. Crie conta em https://vercel.com/ e conecte um repositório GitHub contendo os arquivos desta pasta, ou use o fluxo de importação disponível na plataforma.
2. Configure como projeto estático, sem comando de build; a pasta raiz contém `index.html`.
3. Publique e abra a URL HTTPS gerada no celular.
4. Use “Adicionar à tela inicial” no menu do navegador. Em navegadores compatíveis, o app pode oferecer o botão “Instalar”.
5. Para atualizações, envie os arquivos novos ao repositório e publique novamente.

## Fluxo de teste recomendado

- Registrar uma placa fictícia e 2–4 fotos.
- Tentar registrar a mesma placa novamente antes da saída: deve ser bloqueado.
- Registrar a saída e confirmar que o veículo deixa a lista “No pátio”.
- Verificar se o histórico preserva a entrada, a saída e as fotos.
- Exportar CSV e conferir os horários.
- Entrar com usuário de porteiro e administrador para validar os acessos.
- Fazer esses testes em dois celulares diferentes para confirmar a sincronização em nuvem.

## Próximas melhorias antes da operação completa

- OCR/LPR para leitura automática da placa.
- Visualização de fotos dentro do app (em vez de links temporários).
- Relatórios PDF e filtros avançados.
- Trilhas de auditoria imutáveis e correções com justificativa.
- Retenção de fotos, backup e procedimento para incidentes, conforme política interna e LGPD.
