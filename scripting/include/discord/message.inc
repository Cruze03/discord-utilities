#include <discord/user>

methodmap DiscordMessage < JSON_Object {
	public bool GetID(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "id", buffer, maxlength);
	}
	
	public bool IsPinned() {
		return JsonObjectGetBool(this, "pinned");
	}
	
	public DiscordUser GetAuthor() {
		return view_as<DiscordUser>(this.GetObject("author"));
	}
	
	public bool GetContent(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "content", buffer, maxlength);
	}
	
	public bool GetChannelID(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "channel_id", buffer, maxlength);
	}
}

methodmap DiscordEmbed < JSON_Object {
	public DiscordEmbed() {
		JSON_Object hObj = new JSON_Object();
		return view_as<DiscordEmbed>(hObj);
	}

	public bool GetColor(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "color", buffer, maxlength);
	}

	public void SetColor(const char[] color) {
		this.SetString("color", color);
	}

	public bool GetTitle(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "title", buffer, maxlength);
	}

	public void SetTitle(const char[] title) {
		this.SetString("title", title);
	}

	public bool GetTitleLink(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "title_link", buffer, maxlength);
	}

	public void SetTitleLink(const char[] title_link) {
		this.SetString("title_link", title_link);
	}

	public bool GetImage(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "image_url", buffer, maxlength);
	}

	public void SetImage(const char[] image_url) {
		this.SetString("image_url", image_url);
	}

	public bool GetAuthor(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "author_name", buffer, maxlength);
	}

	public void SetAuthor(const char[] author_name) {
		this.SetString("author_name", author_name);
	}

	public bool GetAuthorLink(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "author_link", buffer, maxlength);
	}

	public void SetAuthorLink(const char[] author_link) {
		this.SetString("author_link", author_link);
	}

	public bool GetAuthorIcon(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "author_icon", buffer, maxlength);
	}

	public void SetAuthorIcon(const char[] author_icon) {
		this.SetString("author_icon", author_icon);
	}

	public bool GetThumb(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "thumb_url", buffer, maxlength);
	}

	public void SetThumb(const char[] thumb_url) {
		this.SetString("thumb_url", thumb_url);
	}

	public bool GetFooter(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "footer", buffer, maxlength);
	}

	public void SetFooter(const char[] footer) {
		this.SetString("footer", footer);
	}

	public bool GetFooterIcon(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "footer_icon", buffer, maxlength);
	}

	public void SetFooterIcon(const char[] footer_icon) {
		this.SetString("footer_icon", footer_icon);
	}
	
	property JSON_Array Fields {
		public get() {
			return view_as<JSON_Array>(this.GetObject("fields"));
		}

		public set(JSON_Array value) {
			if(this.HasKey("fields"))
			{
				this.GetObject("fields").Cleanup();
				delete this.GetObject("fields");
			}
			this.SetObject("fields", value);
		}
	}

	public void AddField(const char[] name, const char[] value, bool inline) {
		JSON_Object hObj = new JSON_Object();
		hObj.SetString("name", name);
		hObj.SetString("value", value);
		hObj.SetBool("inline", inline);

		JSON_Array hArray = this.Fields;
		if(hArray == null) {
			hArray = new JSON_Array();
			this.Fields = hArray;
		}
		hArray.PushObject(hObj);
	}

	public bool GetDescription(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "description", buffer, maxlength);
	}

	public void SetDescription(const char[] description) {
		this.SetString("description", description);
	}

	public bool GetURL(char[] buffer, int maxlength) {
		return JsonObjectGetString(this, "url", buffer, maxlength);
	}

	public void SetURL(const char[] url) {
		this.SetString("url", url);
	}
};