{
	"imports": [
		"fs",
		"path"
	],
	"function syncProfiles": {
		"parameters": [
			"defaultProfilePath",
			"profilesDirectory"
		],
		"body": [
			"const defaultProfile = JSON.parse(fs.readFileSync(defaultProfilePath, 'utf-8'));",
			"const profileFiles = fs.readdirSync(profilesDirectory);",
			"profileFiles.forEach(file => {",
			"    if (file !== 'Default.code-profile') {",
			"        const profilePath = path.join(profilesDirectory, file);",
			"        const profile = JSON.parse(fs.readFileSync(profilePath, 'utf-8'));",
			"        const updatedProfile = { ...defaultProfile, ...profile };",
			"        fs.writeFileSync(profilePath, JSON.stringify(updatedProfile, null, 4));",
			"    }",
			"});"
		]
	}
}