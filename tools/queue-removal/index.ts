import { AuthProvider, LoggerFactory } from '@cua/test-kit';
import { CliOptions } from '../../runner/cli-options';
import { environment } from '../../runner/environment';
import { PlatformGateway } from '@cua/test-kit/data-creation/platform-sdk/platform-gateway';

const logger = LoggerFactory.createNamedLogger('Main');
const cliOptions = CliOptions.parse();

if (!cliOptions.name) {
    throw new Error('No content queue name specified.');
}

async function deleteContentQueueAndAssociations(qName: string) {

    const platformGateway = new PlatformGateway({
        apiConfig: environment.platformApi,
        authProvider: new AuthProvider(environment.authConfig),
    });

    const hxpApp = platformGateway.apiConfig.hxpApp;
    const qListResult = await platformGateway.configurationApi.apiConfigurationContentqueueListGet(hxpApp);

    const qInfo = qListResult.body.contentQueues!.find(q => q.name === qName);

    if (!qInfo) {
        throw new Error(`Content queue "${qName}" not found.`);
    }

    const qDetailsResult = await platformGateway.configurationApi
    .apiConfigurationContentqueueGet(qInfo.ID!, hxpApp);

    // Delete associated batches

    const qBatchesResult = await platformGateway.batchApi.apiBatchListGet(hxpApp, undefined, undefined, qInfo.ID!);

    await Promise.all(qBatchesResult.body.batches!.map(batch =>
        platformGateway.batchApi.apiBatchDelete(batch.ID!, hxpApp)));

    // Delete queue itself
    await platformGateway.configurationApi.apiConfigurationContentqueueDelete(qInfo.ID!, hxpApp);

    // Delete associated doc classes and fields
    await Promise.all(qDetailsResult.body.documentClasses!.map(docClass =>
        platformGateway.configurationApi.apiConfigurationDocumentclassDelete(docClass.ID!, hxpApp)));

    await Promise.all(qDetailsResult.body.documentClasses!.map(docClass => docClass.fields!)
    .reduce((prevValue, currentValue) => prevValue.concat(currentValue))
    .map(field => platformGateway.configurationApi.apiConfigurationFieldDelete(field.ID!, hxpApp)));

    // Delete associated process flow and actions
    const processFlowResult = await platformGateway.configurationApi
    .apiConfigurationProcessflowGet(qDetailsResult.body.activeProcessFlow!.ID!, hxpApp);

    await platformGateway.configurationApi.apiConfigurationProcessflowDelete(processFlowResult.body.ID!, hxpApp);

    await Promise.all(processFlowResult.body.actions!.relations!.map(rel =>
         platformGateway.configurationApi.apiConfigurationActionDelete(rel.ID!, hxpApp)));
}

deleteContentQueueAndAssociations(cliOptions.name).catch(err => {
    logger.error('Error while running test', err);
    process.exit(1);
});