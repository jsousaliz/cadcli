# Notas de versão

Uma nota por versão, no arquivo `vX.Y.Z.md`, com o mesmo `X.Y.Z` informado ao workflow `Criar release CadCli`.

O workflow valida a existência deste arquivo antes de compilar quando `modo_notas` é `arquivo`, e usa o conteúdo como corpo da GitHub Release (`gh release create --notes-file`). Com `modo_notas` igual a `automaticas`, as notas são geradas pelo GitHub a partir dos commits (`--generate-notes`) e nenhum arquivo é exigido.
