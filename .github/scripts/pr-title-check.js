const fs = require("fs");

const eventPath = process.env.GITHUB_EVENT_PATH;
const eventJson = JSON.parse(fs.readFileSync(eventPath, "utf8"));

const prTitle = eventJson.pull_request.title;

const isValidType = (title) =>
	/^(feat|fix|chore|refactor)(\([a-zA-Z0-9-]+\))?:\s[A-Z][a-zA-Z]*$/.test(
		title,
	);

const validateTitle = (title) => {
	if (!isValidType(title)) {
		console.error(
			`PR title does not follow the required format.
      example: "type: My PR Title"
      
      - type: "feat", "fix", "chore", or "refactor"
      - First letter of the PR title needs to be uppercased
      `,
		);
		process.exit(1);
	}

	console.log("PR title is valid");
};

validateTitle(prTitle);
