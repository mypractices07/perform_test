import * as path from 'path';
import { AuthProvider, DataCreationTool, LoggerFactory } from '@cua/test-kit';
import { environment } from '../../runner/environment';

const logger = LoggerFactory.createNamedLogger('PlatformReadinessCheck');

const READINESS_CHECK_DATA = {
  configurationConfig: path.resolve(__dirname, 'data/configuration.json'),
  acquisitionConfig:  path.resolve(__dirname, 'data/content-aquisition.json')
};

async function checkPlatformReadiness(): Promise<void> {
  const authProvider = new AuthProvider(environment.authConfig);

  const dataCreationTool = new DataCreationTool({
    platformConfig: {
      authProvider,
      apiConfig: environment.platformApi,
    },
  });

  try {
    // Clean existing platform data if required (Deletes only batches for now)
    // await dataCreationTool.cleanPlatform();

    const dataScope = dataCreationTool.createDataScope('ReadinessCheck');
    // Create process flows and content queues
    await dataScope.addConfigurationData(READINESS_CHECK_DATA.configurationConfig);
    // Create batches
    await dataScope.onboardContent(READINESS_CHECK_DATA.acquisitionConfig);
  } finally {
    await dataCreationTool.tearDown(); // Cleans data created in all scopes
  }
}

checkPlatformReadiness().catch(err => {
    logger.error('Error while checking platform readiness', err);
    process.exit(1);
});
