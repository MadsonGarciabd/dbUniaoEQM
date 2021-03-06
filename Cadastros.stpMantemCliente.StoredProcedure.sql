USE [dbUniaoEQM]
GO
/****** Object:  StoredProcedure [Cadastros].[stpMantemCliente]    Script Date: 17/11/2021 23:21:46 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*------------------------------------------------------------
Autor      : Madson Garcia
Objeto     : stpMantemCliente
Objetivo   : Atualiza os dados de contato de pessoas que são clientes 
Impacto    : Tabela Cadastros.tPessoa
Regras     : A procedure retorna 0 em caso de sucesso
             em caso de erro retorna o id da tabela de log
--------------------------------------------------------------
Data            Resposável                   Alteração
09/10/2021      Madson Garcia                Criação
------------------------------------------------------------*/
CREATE   PROCEDURE [Cadastros].[stpMantemCliente]
    @cAcao                      CHAR                ='U'
    ,@iIdCliente		    	int                 = -1
    ,@iIdPessoaFK				int					= -1
    ,@iIdColaboradorFK          int                 = -1
    ,@iDiasPgto					int                 = -1
    ,@dImpostos					decimal(19,4)       = 0
    ,@dFatorDespfin				decimal(19,4)       = 0
    ,@vFatorPrePos				char(3)             = 'UNK'
    ,@dDesconto					decimal(19,4)       = 0
    ,@iPortal					INTEGER             = 0
    ,@dComissao					decimal(19,4)       = 0
    ,@dLucro					decimal(19,4)       = 0
    ,@vVendedorUEQM             VARCHAR(50)         ='UNK'
    ,@vCondPagUEQM              VARCHAR(50)         ='UNK'
    ,@vObservacao               VARCHAR(400)        ='UNK'
    ,@vUFUEQM                   VARCHAR(2)          ='UN'
    ,@dICMS						DECIMAL(19,4)       = 0.0
	,@vINC_EXC					varchar(5)          ='UNK'
	,@vEntrega					VARCHAR(5)          ='UNK'
	,@iNumEmpresa				INTEGER             = -1
	,@vNomeEmpresa				varchar(500)        = 'UNK'  
    ,@RETURN_VALUE              VARCHAR(50)         = 0 OUTPUT
AS 
BEGIN
     
    
    BEGIN TRY
        IF (@cAcao = 'U') or (exists (select 1 from Cadastros.tCliente where iIdPessoaFK = @iIdPessoaFK))
        BEGIN
            UPDATE Cliente
            set iIdPessoaFK	        =   @iIdPessoaFK
            ,iIdColaboradorFK       =   @iIdColaboradorFK
            ,iDiasPgto	            =   @iDiasPgto
            ,dImpostos	            =   @dImpostos
            ,dFatorDespfin          =   @dFatorDespfin
            ,vFatorPrePos           =   @vFatorPrePos
            ,dDesconto	            =   @dDesconto
            ,iPortal	            =   @iPortal
            ,dComissao	            =   @iPortal
            ,dLucro		            =   @dLucro
            ,vVendedorUEQM          =   @vVendedorUEQM
            ,vCondPagUEQM           =   @vCondPagUEQM
            ,vObservacao            =   @vObservacao
            ,vUFUEQM                =   @vUFUEQM
            ,dICMS				    =   @dICMS		
			,vINC_EXC				=   @vINC_EXC		
			,vEntrega				=   @vEntrega		
			,iNumEmpresa			=   @iNumEmpresa				
            ,vNomeEmpresa			=   @vNomeEmpresa	
            FROM Cadastros.tCliente Cliente
            WHERE Cliente.iIdPessoaFK = @iIdPessoaFK
            
            IF @@ROWCOUNT = 0 -- Caso id não seja encontrado força um erro para cair no Cath
                BEGIN
                    DECLARE @msg VARCHAR(100) = 'Advertência no Update!! Id.Pessoa ' + convert(varchar,@iIdPessoaFK) + ' Não encotrado na tabela Cadastros.tCliente '
                    raiserror(@msg,16,1)
                END
        END
        ELSE IF @cAcao = 'I'
        BEGIN
            INSERT INTO Cadastros.tCliente
            (   
                iIdPessoaFK
                ,iIdColaboradorFK
                ,iDiasPgto
                ,dImpostos
                ,dFatorDespfin
                ,vFatorPrePos
                ,dDesconto
                ,iPortal
                ,dComissao
                ,dLucro
                ,vVendedorUEQM
                ,vCondPagUEQM
                ,vObservacao
                ,vUFUEQM
                ,dICMS		
			    ,vINC_EXC	
			    ,vEntrega	
			    ,iNumEmpresa
			    ,vNomeEmpresa
            )
            VALUES
            (   
                @iIdPessoaFK
                ,@iIdColaboradorFK
                ,@iDiasPgto
                ,@dImpostos
                ,@dFatorDespfin
                ,@vFatorPrePos
                ,@dDesconto
                ,@iPortal
                ,@dComissao
                ,@dLucro
                ,@vVendedorUEQM
                ,@vCondPagUEQM
                ,@vObservacao
                ,@vUFUEQM
                ,@dICMS		
                ,@vINC_EXC	
                ,@vEntrega	
                ,@iNumEmpresa
                ,@vNomeEmpresa
            )
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
        set @RETURN_VALUE = convert(varchar, SCOPE_IDENTITY ())
        set @vMensagem = @vMensagem + ' idLog = ' + convert(varchar,@RETURN_VALUE)
        set @RETURN_VALUE = '-1,' + @RETURN_VALUE
        Raiserror(@vMensagem,10,1)
    END CATCH
    select @RETURN_VALUE
    
END
GO
