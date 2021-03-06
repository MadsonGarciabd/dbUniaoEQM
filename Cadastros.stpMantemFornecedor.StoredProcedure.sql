USE [dbUniaoEQM]
GO
/****** Object:  StoredProcedure [Cadastros].[stpMantemFornecedor]    Script Date: 17/11/2021 23:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*------------------------------------------------------------
Autor      : Madson Garcia
Objeto     : stpMantemFornecedor
Objetivo   : Atualiza os dados de contato de pessoas que são froncedores
Impacto    : Tabela Cadastros.tPessoa
Regras     : A procedure retorna 0 em caso de sucesso
             em caso de erro retorna o id da tabela de log
--------------------------------------------------------------
Data            Resposável                   Alteração
09/10/2021      Madson Garcia                Criação
------------------------------------------------------------*/
CREATE   PROCEDURE [Cadastros].[stpMantemFornecedor]
    @cAcao                      CHAR(1)             = 'U'
    ,@iIdFonecedor				int                 = -1
    ,@iIdPessoaFK				int				    = -1
    ,@vCodForncedor				varchar(10)         = 'UNK'
    ,@vSeguimento				varchar(100)        = 'UNK'
    ,@vObservacao				VARCHAR(400)        = ''
    ,@RETURN_VALUE              VARCHAR(50)         = 0 OUTPUT
AS 
BEGIN
     
    BEGIN TRY
        set @RETURN_VALUE = '0,' + CONVERT(VARCHAR,@iIdFonecedor)
        IF @cAcao = 'U' or exists ( select 1 from Cadastros.tFornecedor where iIdPessoaFK = @iIdPessoaFK)
        BEGIN
            BEGIN TRANSACTION
                UPDATE Fornecedor
            SET  iIdPessoaFK             =   @iIdPessoaFK
                    ,vCodForncedor          =   @vCodForncedor
                    ,vSeguimento            =   @vSeguimento
                    ,vObservacao            =   @vObservacao
                FROM Cadastros.tFornecedor Fornecedor
                WHERE (Fornecedor.iIdFonecedor = @iIdFonecedor or iIdPessoaFK = @iIdPessoaFK)
                IF @@ROWCOUNT = 0 -- Caso id não seja encontrado força um erro para cair no Cath
                BEGIN
                    DECLARE @msg VARCHAR(100) = 'Advertência no Update!! Id ' + convert(varchar,@iIdFonecedor) + ' Não encotrado na tabela Cadastros.tFornecedor '
                    raiserror(@msg,16,1)
                END
            COMMIT
        END
        ELSE IF @cAcao = 'I' --TRATAIVA PARA ATUALIZAÇÃO DOS DADOS
         BEGIN
            INSERT INTO Cadastros.tFornecedor
            (iIdPessoaFK,vCodForncedor,vSeguimento,vObservacao)
            VALUES
            (@iIdPessoaFK,@vCodForncedor,@vSeguimento,@vObservacao)
            set @RETURN_VALUE = '0,' + convert(varchar,SCOPE_IDENTITY ())
        END
        
    END TRY

    BEGIN CATCH
        If @@TRANCOUNT > 0 -- tem transação aberta? 
            Rollback 

        -- Capturou as informações de erro 
        Declare  @niIDEvento            int = 0 
                ,@vMensagem             varchar(2048) 
                ,@nErrorNumber          int             = ERROR_NUMBER()
                ,@cErrorMessage         varchar(200)    = ERROR_MESSAGE()
                ,@nErrorSeverity        tinyint         = ERROR_SEVERITY()
                ,@nErrorState           tinyint         = ERROR_STATE()
                ,@cErrorProcedure       varchar(128)    = ERROR_PROCEDURE()
                ,@nErrorLine            int =            ERROR_LINE()
        
        Set @vMensagem = FormatMessage('MsgID %d. %s. Severidade %d. Status %d. Procedure %s. Linha %d.',
                                        @nErrorNumber,@cErrorMessage,@nErrorSeverity ,@nErrorState,@cErrorProcedure ,@nErrorLine)
        
        Insert into Cadastros.tLOGEventos (vMensagem) values (@vMensagem) 
        set @RETURN_VALUE = convert(varchar,SCOPE_IDENTITY())
        set @vMensagem = @vMensagem + ' idLog = ' + convert(varchar,@RETURN_VALUE)
        set @RETURN_VALUE = '-1,' + @RETURN_VALUE
        Raiserror(@vMensagem,10,1)
    END CATCH
    
    SELECT @RETURN_VALUE

    
END
GO
