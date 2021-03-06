USE [dbUniaoEQM]
GO
/****** Object:  StoredProcedure [Cadastros].[stpMantemPessoa]    Script Date: 17/11/2021 23:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*------------------------------------------------------------
Autor      : Madson Garcia
Objeto     : stpMantemPessoa
Objetivo   : Atualiza os dados da Pessoa.
Impacto    : Tabela Cadastros.tPessoa, [Cadastros].[tContatoPessoa], 
            [Cadastros].[tCliente], [Cadastros].[tFornecedor],
            [Cadastros].[tEndereco], [Cadastros].[tEmpresa]
Regras     : A procedure retorna 0 em caso de sucesso
             em caso de erro retorna o id da tabela de log
--------------------------------------------------------------
Data            Resposável                   Alteração
09/10/2021      Madson Garcia                Criação
------------------------------------------------------------*/
CREATE   PROCEDURE [Cadastros].[stpMantemPessoa]
    @cAcao                      CHAR                ='U'
    ,@iIdPessoa                 int                 =-1
    ,@iIdEntidadeFK				int		            = 2
    ,@cDocCPFCNPJ				varchar(14)         ='Desconhecido'
    ,@vPrimeiroNome				varchar(100)        ='Desconhecido'
    ,@vSegundoNome				varchar(100)        ='Desconhecido'
    ,@vFantasiaNome				varchar(100)        ='Desconhecido'
    ,@bSituacaoAtiva			BIT                 = 1
    ,@RETURN_VALUE              VARCHAR(50)         = '-1,0' OUTPUT
-- add more stored procedure parameters here
AS
BEGIN
    
    BEGIN TRY 
        set @RETURN_VALUE = '0,' +CONVERT(varchar,@iIdPessoa)
        IF (@cAcao = 'U') or (exists(select 1 from Cadastros.tPessoa where iIdPessoa = @iIdPessoa))
        BEGIN
            UPDATE tPessoa
                set iIdEntidadeFK           =   @iIdEntidadeFK
                    ,cDocCPFCNPJ	        =   @cDocCPFCNPJ
                    ,vPrimeiroNome          =   trim(@vPrimeiroNome)
                    ,vSegundoNome	        =   trim(@vSegundoNome)
                    ,vFantasiaNome          =   trim(@vFantasiaNome)
                    ,bSituacaoAtiva         =   @bSituacaoAtiva
            FROM Cadastros.tPessoa tPessoa
            WHERE tPessoa.iIdPessoa = @iIdPessoa
            IF @@ROWCOUNT = 0 -- Caso id não seja encontrado força um erro para cair no Cath
                BEGIN
                    DECLARE @msg VARCHAR(100) = 'Advertência no Update!! Id ' + convert(varchar,@iIdPessoa) + ' Não encotrado na tabela Cadastros.tPessoa '
                    raiserror(@msg,16,1)
                END
        END
        ELSE IF @cAcao = 'I'
        BEGIN
            INSERT INTO Cadastros.tPessoa
            (iIdEntidadeFK,cDocCPFCNPJ,vPrimeiroNome,vSegundoNome,vFantasiaNome)
            VALUES
            (@iIdEntidadeFK,trim(@cDocCPFCNPJ),trim(@vPrimeiroNome),trim(@vSegundoNome),trim(@vFantasiaNome))
            set @RETURN_VALUE = '0,' + CONVERT(VARCHAR, SCOPE_IDENTITY ())
        END
        
        
    END TRY

    BEGIN CATCH
        If @@TRANCOUNT > 0 -- tem transação aberta? 
            Rollback 

        -- Capturou as informações de erro 
        Declare  @niIDEvento            int = 0 
                ,@vMensagem             varchar(512) 
                ,@nErrorNumber          int             = ERROR_NUMBER()
                ,@cErrorMessage         varchar(200)    = ERROR_MESSAGE()
                ,@nErrorSeverity        tinyint         = ERROR_SEVERITY()
                ,@nErrorState           tinyint         = ERROR_STATE()
                ,@cErrorProcedure       varchar(128)    = ERROR_PROCEDURE()
                ,@nErrorLine            int =            ERROR_LINE()
        
        Set @vMensagem = FormatMessage('MsgID %d. %s. Severidade %d. Status %d. Procedure %s. Linha %d.',
                                        @nErrorNumber,@cErrorMessage,@nErrorSeverity ,@nErrorState,@cErrorProcedure ,@nErrorLine)
        
        Insert into Cadastros.tLOGEventos (vMensagem) values (@vMensagem) 
        set @RETURN_VALUE = convert(varchar, SCOPE_IDENTITY ())
        set @vMensagem = @vMensagem + ' idLog = ' + @RETURN_VALUE
        set @RETURN_VALUE = '-1,' + @RETURN_VALUE
        Raiserror(@vMensagem,10,1)
    END CATCH
    select @RETURN_VALUE
    

    
END
GO
