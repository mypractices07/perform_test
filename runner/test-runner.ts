import { AuthProvider, DataCreationTool } from '@cua/test-kit';
import { environment } from './environment';
import { spawn } from 'child_process';

export class TestRunner {
  static async run(suiteName: string, testName: string, numberOfUsers: number, rampup: number): Promise<void> {
    const authProvider = new AuthProvider(environment.authConfig);
    const dataCreationTool = new DataCreationTool({
      platformConfig: {
        authProvider,
        apiConfig: environment.platformApi,
      },
    });

    try {
      
      // Clean existing platform data if required (Deletes only batches for now)
       await dataCreationTool.cleanPlatform();
        console.log("entry point1");
      const dataScope = dataCreationTool.createDataScope(suiteName);
      console.log("entry point2");
      const suiteDataConfig = environment.dataSetup.suiteData[suiteName];
      console.log("entry point3");
      // Create process flows and content queues
      await dataScope.addConfigurationData(suiteDataConfig.configurationConfig);
      console.log("entry point4");
      // Create batches
      await dataScope.onboardContent(suiteDataConfig.acquisitionConfig);
      console.log("entry point5");

      await TestRunner.runJmeter(suiteName, testName, numberOfUsers, rampup);
      console.log("Jmeter Script Done");
      await TestRunner.mergeResultFiles(suiteName);
      console.log("Merging Result Done");

    } finally {
      await dataCreationTool.tearDown(); // Cleans data created in all scopes
    }
  }

  private static async runJmeter(suiteName: string, testName: string, numberOfUsers: number, rampup: number): Promise<unknown> {
    return new Promise<unknown>((resolve, reject) => {
      console.log('current working directory', process.cwd());
      const cmd = ['jmeter.bat', '-n', '-t', `.\\jmx\\${testName}.jmx`, '-l', `${suiteName}.jtl`, '-Duser.classpath=./dependencies', `-Jusers=${numberOfUsers}`, `-Jrampup=${rampup}`, `-JcsvPath=${suiteName}`];
      console.log('jmeter command: ', cmd.join(' '));
      const child = spawn('cmd.exe', ['/c', ...cmd]);
      child.stdout.on('data', msg => {
        console.log('jmeter ', msg.toString());
      });
      child.stderr.on('data', msg => {
        console.log('jmeter ', msg.toString());
      });
      child.on('exit', () => {
       resolve();
      });
      console.log("entry point7");
    });
  }

  private static async mergeResultFiles(suiteName: string) : Promise<unknown> {
    return new Promise<unknown>((resolve, reject) => {
      console.log('current working directory', process.cwd());
      const cmd = ['JMeterPluginsCMD.bat', '--generate-csv', `mergedReport-${suiteName}.csv`, '--input-jtl', `.\\merge-results-${suiteName}.properties`, '--plugin-type', `MergeResults`];
      console.log('jmeter merge plugin command: ', cmd.join(' '));
      const child = spawn('cmd.exe', ['/c', ...cmd]);
      child.stdout.on('data', msg => {
        console.log('jmeter ', msg.toString());
      });
      child.stderr.on('data', msg => {
        console.log('jmeter ', msg.toString());
      });
      child.on('exit', () => {
       resolve();
      });
      console.log("entry point8");
    });
  }
}
