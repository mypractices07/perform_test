import { LogLevel, HxpApp } from '@cua/test-kit';


export const environment = {
  logLevel:
    (process.env.PERF_LOG_LEVEL && parseInt(process.env.PERF_LOG_LEVEL, 10)) ||
    LogLevel.Debug,
  authConfig: {
    clientConfig: {
      client: {
        id: 'test-client',
        secret: 'secret-123',
      },
      auth: {
        tokenHost: process.env.IDP_BASE || 'http://10.40.2.98:9870',
        tokenPath: '/idp/connect/token',
      },
    },
    userTokenConfig: {
      username: process.env.DATA_CREATION_USERNAME || 'user1@email.com',
      password: process.env.DATA_CREATION_USERPWD || 'password',
      scope: process.env.DATA_CREATION_USERSCOPE || 'hxp',
    },
  },
  platformApi: {
    baseUrl: process.env.PLATFORM_API || 'http://localhost:9000',
    hxpTenantId: process.env.TENANT_ID || 'gc-faculty',
    hxpApp: 'hxc' as HxpApp,
  },
  dataSetup: {
    suiteData: {
      'graphQLloadwithsingleuser': {
        acquisitionConfig: 'test-data/suites/graphQLloadwithsingleuser/content-aquisition.json',
        configurationConfig: 'test-data/suites/graphQLloadwithsingleuser/configuration.json'
      },
      'graphQLResponse-singleUser-50batches': {
        acquisitionConfig: 'test-data/suites/graphQLResponse-singleUser-50batches/content-aquisition.json',
        configurationConfig: 'test-data/suites/graphQLResponse-singleUser-50batches/configuration.json'
      },
      'graphQLResponse-singleUser-100batches': {
        acquisitionConfig: 'test-data/suites/graphQLResponse-singleUser-100batches/content-aquisition.json',
        configurationConfig: 'test-data/suites/graphQLResponse-singleUser-50batches/configuration.json'
      },
      'graphQLResponse-singleUser-150batches': {
        acquisitionConfig: 'test-data/suites/graphQLResponse-singleUser-150batches/content-aquisition.json',
        configurationConfig: 'test-data/suites/graphQLResponse-singleUser-50batches/configuration.json'
      },

    } as {
      [suiteName: string]: { acquisitionConfig: string; configurationConfig: string; }
    },
  },
};


