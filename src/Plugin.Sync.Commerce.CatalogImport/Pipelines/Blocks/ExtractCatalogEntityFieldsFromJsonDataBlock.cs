﻿using Newtonsoft.Json.Linq;
using Plugin.Sync.Commerce.CatalogImport.Extensions;
using Plugin.Sync.Commerce.CatalogImport.Models;
using Plugin.Sync.Commerce.CatalogImport.Pipelines.Arguments;
using Plugin.Sync.Commerce.CatalogImport.Policies;
using Sitecore.Commerce.Core;
using Sitecore.Commerce.Plugin.Catalog;
using Sitecore.Framework.Conditions;
using Sitecore.Framework.Pipelines;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Plugin.Sync.Commerce.CatalogImport.Pipelines.Blocks
{
    /// <summary>
    /// Extract Commerce Entity fields from input JSON using Entity's MappingPolicy to find matching fields in input JSON
    /// </summary>
    [PipelineDisplayName("ExtractCatalogEntityFieldsFromJsonDataBlock")]
    public class ExtractCatalogEntityFieldsFromJsonDataBlock : PipelineBlock<ImportCatalogEntityArgument, ImportCatalogEntityArgument, CommercePipelineExecutionContext>
    {
        public ExtractCatalogEntityFieldsFromJsonDataBlock()
        {
        }

        //private IEnumerable<string> GetParentEntityIDs(JObject entityData, MappingPolicyBase mappingPolicy)
        //{
        //    var relationUrl = entityData.SelectValue<string>(mappingPolicy.ParentRelationEntityPath);
        //    if (!string.IsNullOrEmpty(relationUrl))
        //    {
        //        var relationEntity = 
        //    }
        //}

        /// <summary>
        /// Main execution point
        /// </summary>
        /// <param name="arg"></param>
        /// <param name="context"></param>
        /// <returns></returns>
        public override async Task<ImportCatalogEntityArgument> Run(ImportCatalogEntityArgument arg, CommercePipelineExecutionContext context)
        {
            var mappingPolicy = arg.MappingPolicy;

            var jsonData = arg.Entity as JObject;
            Condition.Requires(jsonData, "Commerce Entity JSON parameter is required").IsNotNull();
            context.AddModel(new JsonDataModel(jsonData));

            var entityDataModel = context.GetModel<CatalogEntityDataModel>();
            var entityData = new CatalogEntityDataModel
            {
                EntityId = jsonData.SelectValue<string>(mappingPolicy.EntityId),
                EntityName = jsonData.SelectValue<string>(mappingPolicy.EntityName),
                ParentCatalogName = jsonData.SelectValue<string>(mappingPolicy.ParentCatalogName),
                //ParentCategoryName = jsonData.SelectValue<string>(mappingPolicy.ParentCategoryName),
                EntityFields = jsonData.SelectMappedValues(mappingPolicy.EntityFieldsPaths),
                ComposerFields = jsonData.SelectMappedValues(mappingPolicy.ComposerFieldsPaths),
                CustomFields = jsonData.SelectMappedValues(mappingPolicy.CustomFieldsPaths),
            };

            entityData.EntityFields.AddRange(jsonData.QueryMappedValuesFromRoot(mappingPolicy.EntityFieldsRootPaths));
            entityData.ComposerFields.AddRange(jsonData.QueryMappedValuesFromRoot(mappingPolicy.ComposerFieldsRootPaths));
            entityData.CustomFields.AddRange(jsonData.QueryMappedValuesFromRoot(mappingPolicy.CustomFieldsRootPaths));

            if (string.IsNullOrEmpty(entityData.ParentCatalogName))
            {
                entityData.ParentCatalogName = mappingPolicy.DefaultCatalogName;
            }

            //if (string.IsNullOrEmpty(entityData.ParentCategoryName))
            //{
            //    entityData.ParentCategoryName = mappingPolicy.DefaultCategoryName;
            //}

            if (!string.IsNullOrEmpty(mappingPolicy.ListPrice))
            {
                var price = jsonData.SelectValue<string>(mappingPolicy.ListPrice);
                if (!string.IsNullOrEmpty(price))
                {
                    decimal parcedPrice;
                    if (decimal.TryParse(price, out parcedPrice))
                    {
                        entityData.ListPrice = parcedPrice;
                    }
                }
            }

            arg.ParentEntityIds = new List<string>();
            if (arg.ParentRelationsEntity != null && !string.IsNullOrEmpty(mappingPolicy.ParentRelationParentsPath))
            {
                var parentTokens = arg.ParentRelationsEntity.SelectTokens(mappingPolicy.ParentRelationParentsPath);
                if (parentTokens != null )
                {
                    foreach (JToken parentToken in parentTokens)
                    {
                        var parentUrl = parentToken.Value<string>();
                        if (!string.IsNullOrEmpty(parentUrl))
                        {
                            var parentEntityId = parentUrl.Split('/').LastOrDefault();
                            if (long.TryParse(parentEntityId, out long value))
                            {
                                arg.ParentEntityIds.Add(parentEntityId);
                            }
                        }
                    }
                }
            }

            if (arg.CommerceEntityType != null && !string.IsNullOrEmpty(entityData.EntityName))
            {
                if (arg.CommerceEntityType == typeof(Category) && !string.IsNullOrEmpty(entityData.ParentCatalogName))
                {
                    entityData.CommerceEntityId = $"{CommerceEntity.IdPrefix<Category>()}{entityData.ParentCatalogName}-{entityData.EntityName}";
                }
                else if (arg.CommerceEntityType == typeof(SellableItem))
                {
                    entityData.CommerceEntityId = $"{CommerceEntity.IdPrefix<SellableItem>()}{entityData.EntityId}";
                }
            }

            context.AddModel(entityData);

            await Task.CompletedTask;

            return arg;
        }
    }
}
