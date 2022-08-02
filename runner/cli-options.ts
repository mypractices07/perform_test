export class CliOptions {

  static parse() {
    const commands = process.argv.slice(2);
    const options: { [key: string]: string } = {};
    for (const command of commands) {
      const option = this.parseCliArg(command);
      if (option) {
        options[option.key] = option.value;
      }
    }
    return options;
  }

  private static parseCliArg(command: string) {
    const argRegExp = /(.*)=(.*)/;
    const argMatch = command.match(argRegExp);
    if (argMatch) {
      return {
        key: argMatch[1],
        value: argMatch[2],
      };
    }
  }
}
