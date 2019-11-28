using Microsoft.Extensions.DependencyInjection;
using Plugin.Sync.Commerce.CatalogExport.Pipelines;
using PPlugin.Sync.Commerce.CatalogExport.Pipelines.Blocks;
//using Plugin.Sync.Commerce.CatalogExport.Pipelines.Blocks;
using Sitecore.Commerce.Core;
using Sitecore.Framework.Configuration;
using Sitecore.Framework.Pipelines.Definitions.Extensions;
using System.Reflection;

namespace Plugin.Sync.Commerce.CatalogExport
{
    public class ConfigureSitecore : IConfigureSitecore
    {
        public void ConfigureServices(IServiceCollection services)
        {
            var assembly = Assembly.GetExecutingAssembly();
            services.RegisterAllPipelineBlocks(assembly);

            services.Sitecore().Pipelines(config => config
                .ConfigurePipeline<IConfigureServiceApiPipeline>(configure => configure.Add<ConfigureServiceApiBlock>())

                 .AddPipeline<IExportCommerceEntityPipeline, ExportCommerceEntityPipeline>(
                    configure =>
                    {
                        configure.Add<RenderEntityViewBlock>();
                    }));

            services.RegisterAllCommands(assembly);
        }
    }
}