USE [dbUniaoEQM]
GO
/****** Object:  StoredProcedure [Cadastros].[stpMantemColaboradores]    Script Date: 17/11/2021 23:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*------------------------------------------------------------
Autor      : Madson Garcia
Objeto     : stpMantemColaboradores
Objetivo   : Atualiza os dados da colaboradores da Pessoa, 
Impacto    : Tabela Cadastros.tPessoa Cadastros.tCliente
Regras     : A procedure retorna 0 em caso de sucesso
             em caso de erro retorna o id da tabela de log
--------------------------------------------------------------
Data            Resposável                   Alteração
09/10/2021      Madson Garcia                Criação
------------------------------------------------------------*/
CREATE   PROCEDURE [Cadastros].[stpMantemColaboradores]
    @cAcao                   CHAR            ='U'
    ,@iIdColaborador		int             = -1
    ,@iIdPessoaFK			INT				= -1
    ,@iIdCargoFK			INT				= -1
    ,@dDataAdmissao			DATETIME        = GETDATE
    ,@dDataDemissao			DATETIME        = GETDATE
    ,@RETURN_VALUE          VARCHAR(50)     = '-1,0' OUTPUT
-- add more stored procedure parameters here
AS
BEGIN
     
    BEGIN TRY
        
        IF @cAcao = 'U'
        BEGIN
            set @RETURN_VALUE = '0,' + CONVERT(varchar,@iIdColaborador)
            UPDATE Colaborador
               set Colaborador.iIdCargoFK           =   @iIdCargoFK
                   ,Colaborador.dDataAdmissao       =   @dDataAdmissao
                   ,Colaborador.dDataDemissao       =   @dDataDemissao

                FROM Cadastros.tColaborador Colaborador
                WHERE Colaborador.iIdColaborador = @iIdColaborador
            IF @@ROWCOUNT = 0 -- Caso id não seja encontrado força um erro para cair no Cath
                BEGIN
                    DECLARE @msg VARCHAR(100) = 'Advertência no Update!! Id ' + convert(varchar,@iIdColaborador) + ' Não encotrado na tabela Cadastros.tColaborador '
                    raiserror(@msg,16,1)
                END
        END
        ELSE IF @cAcao = 'I'
        BEGIN
            INSERT INTO Cadastros.tColaborador
            (iIdPessoaFK,iIdCargoFK)
            VALUES
            (@iIdPessoaFK,@iIdCargoFK)
            set @RETURN_VALUE = '0,' + CONVERT(VARCHAR, SCOPE_IDENTITY ())
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
        set @RETURN_VALUE = convert(varchar,SCOPE_IDENTITY ())
        set @vMensagem = @vMensagem + ' idLog = ' + convert(varchar,@RETURN_VALUE)
        set @RETURN_VALUE = '-1,' + @RETURN_VALUE
        Raiserror(@vMensagem,10,1)
    END CATCH
    RETURN @RETURN_VALUE
    
END
GO
