# Contrações — instruções para o Claude

## Commits

Após **toda alteração de código**, crie um commit semântico seguindo o padrão do projeto:

```
tipo: descrição curta em português
```

Tipos válidos: `feat`, `fix`, `refactor`, `docs`, `chore`, `style`, `test`.

Exemplos do histórico:
- `feat: adiciona seleção de nível de dor após registro de contração`
- `fix: alerta de maternidade dispara com 5 contrações ou mais`
- `refactor: elimina duplicação de código e aplica boas práticas Flutter`
- `docs: atualiza README com suporte iOS e novos screenshots`

Regras:
- Descrição sempre em **português**
- Sem ponto final
- Adicionar corpo do commit quando a mudança precisar de mais contexto
- Incluir apenas arquivos relevantes (não commitar `.metadata`, pastas de build, etc.)
