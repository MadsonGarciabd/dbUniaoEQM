USE [dbUniaoEQM]
GO
/****** Object:  StoredProcedure [Cadastros].[stpMantemTipoContato]    Script Date: 17/11/2021 23:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*------------------------------------------------------------
Autor      : Madson Garcia
Objeto     : stpMantemTipoContato
Objetivo   : Atualiza os dados de tipo de contato da pessoa (Email, Telefone).
Impacto    : Tabela Cadastros.tPessoa
Regras     : A procedure retorna 0 em caso de sucesso
             em caso de erro retorna o id da tabela de log
--------------------------------------------------------------
Data            Resposável                   Alteração
09/10/2021      Madson Garcia                Criação
------------------------------------------------------------*/
CREATE   PROCEDURE [Cadastros].[stpMantemTipoContato]
    @cAcao                       CHAR               ='U'
    ,@iIdTipoContato             INT                = -1
    ,@vDesTipoContato            VARCHAR(15)        = 'Desconhecido'
    ,@RETURN_VALUE               VARCHAR(50)        = '-1,0' OUTPUT
AS 
BEGIN
    BEGIN TRY
        set @RETURN_VALUE = '0,' + CONVERT(varchar,@iIdTipoContato)
        IF @cAcao = 'U'
        BEGIN
             BEGIN TRANSACTION
                UPDATE TipoContato
                    set vDesTipoContato = @vDesTipoContato
                FROM Cadastros.tTipoContato TipoContato
                WHERE TipoContato.iIdTipoContato = @iIdTipoContato
                IF @@ROWCOUNT = 0 -- Caso id não seja encontrado força um erro para cair no Cath
                BEGIN
                    DECLARE @msg VARCHAR(100) = 'Advertência no Update!! Id ' + convert(varchar,@iIdTipoContato) + ' Não encotrado na tabela Cadastros.tTipoContato '
                    raiserror(@msg,16,1)
                END
            COMMIT
            set @RETURN_VALUE = '0,'+ CONVERT(varchar,@iIdTipoContato)
        END
        ELSE IF @cAcao  = 'I'
        BEGIN
            INSERT INTO Cadastros.tTipoContato
            (vDesTipoContato)
            VALUES
            (@vDesTipoContato)
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
                ,@nErrorLine            int             = ERROR_LINE()
        
        Set @vMensagem = FormatMessage('MsgID %d. %s. Severidade %d. Status %d. Procedure %s. Linha %d.',
                                        @nErrorNumber,@cErrorMessage,@nErrorSeverity ,@nErrorState,@cErrorProcedure ,@nErrorLine)
        
        Insert into Cadastros.tLOGEventos (vMensagem) values (@vMensagem) 
        set @RETURN_VALUE = convert(varchar,SCOPE_IDENTITY ())
        set @vMensagem = @vMensagem + ' idLog = ' + convert(varchar,@RETURN_VALUE)
        set @RETURN_VALUE = '-1,' + @RETURN_VALUE
        Raiserror(@vMensagem,10,1)
    END CATCH

    
END
GO
