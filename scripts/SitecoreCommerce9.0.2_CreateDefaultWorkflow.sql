-- Get environments from global environment.
DECLARE @Environments TABLE(id UNIQUEIDENTIFIER)
INSERT INTO @Environments
	SELECT DISTINCT JSON_VALUE([Entity], '$.ArtifactStoreId')
	FROM [SitecoreCommerce9_Global].[dbo].[CommerceEntities]
	WHERE Id LIKE 'Entity-CommerceEnvironment-%'

-- Create entity and list reference
DECLARE @EnvironmentCursor CURSOR
DECLARE @EnvironmentId VARCHAR(MAX)
BEGIN
	SET @EnvironmentCursor = CURSOR FOR SELECT id FROM @Environments
	OPEN @EnvironmentCursor FETCH NEXT FROM @EnvironmentCursor INTO @EnvironmentId

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Add workflow entity
		INSERT INTO [SitecoreCommerce9_SharedEnvironments].[dbo].[CommerceEntities] (Id, EnvironmentId, Version, Entity, EntityVersion, Published) VALUES ('Entity-Workflow-DefaultCommerceWorkflow', @EnvironmentId, 1, '{"$type":"Sitecore.Commerce.Plugin.Workflow.Workflow, Sitecore.Commerce.Plugin.Workflow","States":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Plugin.Workflow.WorkflowState, Sitecore.Commerce.Plugin.Workflow]], mscorlib","$values":[{"$type":"Sitecore.Commerce.Plugin.Workflow.WorkflowState, Sitecore.Commerce.Plugin.Workflow","DisplayName":"Draft","FinalState":false,"Commands":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Plugin.Workflow.WorkflowCommand, Sitecore.Commerce.Plugin.Workflow]], mscorlib","$values":[{"$type":"Sitecore.Commerce.Plugin.Workflow.WorkflowCommand, Sitecore.Commerce.Plugin.Workflow","NextState":"AwaitingApproval","Name":"Submit","Policies":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Core.Policy, Sitecore.Commerce.Core]], mscorlib","$values":[]}}]},"Name":"Draft","Policies":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Core.Policy, Sitecore.Commerce.Core]], mscorlib","$values":[]}},{"$type":"Sitecore.Commerce.Plugin.Workflow.WorkflowState, Sitecore.Commerce.Plugin.Workflow","DisplayName":"Awaiting Approval","FinalState":false,"Commands":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Plugin.Workflow.WorkflowCommand, Sitecore.Commerce.Plugin.Workflow]], mscorlib","$values":[{"$type":"Sitecore.Commerce.Plugin.Workflow.WorkflowCommand, Sitecore.Commerce.Plugin.Workflow","NextState":"Approved","Name":"Approve","Policies":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Core.Policy, Sitecore.Commerce.Core]], mscorlib","$values":[]}},{"$type":"Sitecore.Commerce.Plugin.Workflow.WorkflowCommand, Sitecore.Commerce.Plugin.Workflow","NextState":"Draft","Name":"Reject","Policies":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Core.Policy, Sitecore.Commerce.Core]], mscorlib","$values":[]}}]},"Name":"AwaitingApproval","Policies":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Core.Policy, Sitecore.Commerce.Core]], mscorlib","$values":[]}},{"$type":"Sitecore.Commerce.Plugin.Workflow.WorkflowState, Sitecore.Commerce.Plugin.Workflow","DisplayName":"Approved","FinalState":true,"Commands":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Plugin.Workflow.WorkflowCommand, Sitecore.Commerce.Plugin.Workflow]], mscorlib","$values":[]},"Name":"Approved","Policies":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Core.Policy, Sitecore.Commerce.Core]], mscorlib","$values":[]}}]},"Components":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Core.Component, Sitecore.Commerce.Core]], mscorlib","$values":[{"$type":"Sitecore.Commerce.Plugin.ManagedLists.ListMembershipsComponent, Sitecore.Commerce.Plugin.ManagedLists","Memberships":{"$type":"System.Collections.Generic.List`1[[System.String, mscorlib]], mscorlib","$values":["Workflows"]},"Id":"545fa8f504464da2a51878ee202d3e77","Name":"","Comments":"","Policies":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Core.Policy, Sitecore.Commerce.Core]], mscorlib","$values":[]},"ChildComponents":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Core.Component, Sitecore.Commerce.Core]], mscorlib","$values":[]}}]},"DateCreated":"2018-07-03T14:33:58.1299612+00:00","DateUpdated":"2018-07-03T14:33:58.3899751+00:00","DisplayName":"Default Commerce Workflow","FriendlyId":"DefaultCommerceWorkflow","Id":"Entity-Workflow-DefaultCommerceWorkflow","Version":1,"EntityVersion":1,"Published":true,"IsPersisted":true,"Name":"DefaultCommerceWorkflow","Policies":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Core.Policy, Sitecore.Commerce.Core]], mscorlib","$values":[]}}', 1, 1)

		-- Add list reference
		INSERT INTO [SitecoreCommerce9_SharedEnvironments].[dbo].[CommerceLists] (ListName, EnvironmentId, CommerceEntityId, EntityVersion) VALUES ('List-workflows-ByDate', @EnvironmentId, 'Entity-Workflow-DefaultCommerceWorkflow', 1)

		FETCH NEXT FROM @EnvironmentCursor INTO @EnvironmentId
	END
END

DECLARE @AllTableNames TABLE(name VARCHAR(MAX))
INSERT INTO @AllTableNames SELECT name FROM sysobjects WHERE xtype = 'U'

DECLARE @EntityTableNames TABLE(name VARCHAR(MAX))
INSERT INTO @EntityTableNames SELECT name from @AllTableNames WHERE name LIKE '%Entities'

-- Update entity tables
DECLARE @EntityTableCursor CURSOR
DECLARE @EntityTableName VARCHAR(MAX)
BEGIN
	SET @EntityTableCursor = CURSOR FOR SELECT name FROM @EntityTableNames
	OPEN @EntityTableCursor FETCH NEXT FROM @EntityTableCursor INTO @EntityTableName

	WHILE @@FETCH_STATUS = 0
	BEGIN
		DECLARE @QuotedEntityTableName VARCHAR(MAX) = QUOTENAME(@EntityTableName)
		
		EXEC('UPDATE ' + @QuotedEntityTableName + ' SET Entity = JSON_MODIFY(Entity, ''append $.Components."$values"'', JSON_QUERY(N''{"$type":"Sitecore.Commerce.Plugin.Workflow.WorkflowComponent, Sitecore.Commerce.Plugin.Workflow","Workflow":{"$type":"Sitecore.Commerce.Core.EntityReference, Sitecore.Commerce.Core","Name":"DefaultCommerceWorkflow","EntityTarget":"Entity-Workflow-DefaultCommerceWorkflow","Policies":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Core.Policy, Sitecore.Commerce.Core]], mscorlib","$values":[]}},"CurrentState":"Approved","Id":"c80d94b660f54a32a789760d26634f14","Name":"","Comments":"","Policies":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Core.Policy, Sitecore.Commerce.Core]], mscorlib","$values":[]},"ChildComponents":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Core.Component, Sitecore.Commerce.Core]], mscorlib","$values":[]}}]}'')) WHERE Id LIKE ''Entity-Catalog-%''')
		EXEC('UPDATE ' + @QuotedEntityTableName + ' SET Entity = JSON_MODIFY(Entity, ''append $.Components."$values"'', JSON_QUERY(N''{"$type":"Sitecore.Commerce.Plugin.Workflow.WorkflowComponent, Sitecore.Commerce.Plugin.Workflow","Workflow":{"$type":"Sitecore.Commerce.Core.EntityReference, Sitecore.Commerce.Core","Name":"DefaultCommerceWorkflow","EntityTarget":"Entity-Workflow-DefaultCommerceWorkflow","Policies":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Core.Policy, Sitecore.Commerce.Core]], mscorlib","$values":[]}},"CurrentState":"Approved","Id":"c80d94b660f54a32a789760d26634f14","Name":"","Comments":"","Policies":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Core.Policy, Sitecore.Commerce.Core]], mscorlib","$values":[]},"ChildComponents":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Core.Component, Sitecore.Commerce.Core]], mscorlib","$values":[]}}]}'')) WHERE Id LIKE ''Entity-Category-%''')
		EXEC('UPDATE ' + @QuotedEntityTableName + ' SET Entity = JSON_MODIFY(Entity, ''append $.Components."$values"'', JSON_QUERY(N''{"$type":"Sitecore.Commerce.Plugin.Workflow.WorkflowComponent, Sitecore.Commerce.Plugin.Workflow","Workflow":{"$type":"Sitecore.Commerce.Core.EntityReference, Sitecore.Commerce.Core","Name":"DefaultCommerceWorkflow","EntityTarget":"Entity-Workflow-DefaultCommerceWorkflow","Policies":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Core.Policy, Sitecore.Commerce.Core]], mscorlib","$values":[]}},"CurrentState":"Approved","Id":"c80d94b660f54a32a789760d26634f14","Name":"","Comments":"","Policies":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Core.Policy, Sitecore.Commerce.Core]], mscorlib","$values":[]},"ChildComponents":{"$type":"System.Collections.Generic.List`1[[Sitecore.Commerce.Core.Component, Sitecore.Commerce.Core]], mscorlib","$values":[]}}]}'')) WHERE Id LIKE ''Entity-SellableItem-%''')

		FETCH NEXT FROM @EntityTableCursor INTO @EntityTableName
	END
END
