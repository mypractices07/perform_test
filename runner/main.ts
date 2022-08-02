import { TestRunner } from './test-runner';
import { LoggerFactory } from '@cua/test-kit';
import { CliOptions } from './cli-options';

const logger = LoggerFactory.createNamedLogger('Main');
const cliOptions = CliOptions.parse();

if (!cliOptions.suiteName) {
    throw new Error('No suite name specified.');
}
if (!cliOptions.testName) {
    throw new Error('No test name specified.');
}
if (!cliOptions.numberOfUsers) {
    throw new Error('No number of users specified.');
}
if (!cliOptions.rampup) {
    throw new Error('No ramp Up specified.');
}

// tslint:disable-next-line: radix
// tslint:disable-next-line: max-line-length
// tslint:disable-next-line: radix
// tslint:disable-next-line: max-line-length
// tslint:disable-next-line: radix
// tslint:disable-next-line: max-line-length
TestRunner.run(cliOptions.suiteName, cliOptions.testName, parseInt(cliOptions.numberOfUsers, 10), parseInt(cliOptions.rampup)).catch(err => {
    console.log('current working directory', process.cwd());
    logger.error('Error while running test', err);
    process.exit(1);
});