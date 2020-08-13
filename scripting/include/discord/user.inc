methodmap DiscordUser < JSON_Object {
	public bool GetID(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "id", buffer, maxlength);
	}
	
	public bool GetUsername(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "username", buffer, maxlength);
	}
	
	public bool GetDiscriminator(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "discriminator", buffer, maxlength);
	}
	public int GetDiscriminatorInt() {
		char buffer[16];
		this.GetDiscriminator(buffer, sizeof(buffer));
		return StringToInt(buffer);
	}
	
	public bool GetAvatar(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "avatar", buffer, maxlength);
	}
	
	public bool IsVerified() {
		return JsonObjectGetBool(this, "verified");
	}
	
	public bool GetEmail(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "email", buffer, maxlength);
	}
	
	public bool IsBot() {
		return JsonObjectGetBool(this, "bot");
	}
};

methodmap DiscordGuildUser < DiscordUser {
	//Returns User Object
	property DiscordUser AsUser {
		public get() { return view_as<DiscordUser>(this); }
	}
	
	//Returns player's nick
	public void GetNickname(char[] buffer, int maxlength) {
		JsonObjectGetString(this, "nick", buffer, maxlength);
	}
	
	//Returns JSON array list of roles. You can manually loop through them for now.
	public JSON_Object GetRoles() {
		return this.GetObject("roles");
	}
	
	//Returns the date the user joined the guild in format: "2015-04-26T06:26:56.936000+00:00"
	public void GetJoinedAt(char[] buffer, int maxlength) {
		JsonObjectGetString(this, "joined_at", buffer, maxlength);
	}
	
	public bool IsDeaf() {
		return JsonObjectGetBool(this, "deaf");
	}
	
	public bool IsMute() {
		return JsonObjectGetBool(this, "mute");
	}
};
