### A Pluto.jl notebook ###
# v0.16.0

using Markdown
using InteractiveUtils

# ╔═╡ c17cdcb5-6b4c-4528-a471-304383bd736a
begin
    import Pkg
    # activate a clean environment
    Pkg.activate(mktempdir())
	pkgs = 
    Pkg.add(
		["Cascadia","Gumbo","HTTP","DataFrames"] .|>
		name -> Pkg.PackageSpec(name=name))
	using Cascadia, Gumbo, HTTP, DataFrames
end

# ╔═╡ 215ff1a2-d65a-49c3-9a6e-aa394f420342
@eval(PlutoRunner, table_row_display_limit = 270)

# ╔═╡ 3a72039c-97c4-4b64-87f5-eba76879cd24
read_url(url) = url |> HTTP.get |> x -> x.body |> String |> parsehtml

# ╔═╡ e4bf36f4-8382-437d-8c86-14a6808227dd
const daily_schedule_url = "https://www.webtoons.com/en/dailySchedule"

# ╔═╡ a534f08a-cca2-4456-b77e-9e78c4d3b44f
values_getters = [
	("Score", x->parse(Float64, x), "#_starScoreAverage"),
	("Genre", x->x, ".detail_header>.info>.genre"),
	("Name", x->x, ".detail_header>.info>.subj"),
]

# ╔═╡ 3486e367-1e67-4e78-9693-8e53e6907e1f
function get_all_completed_series_urls(daily_schedule_url)
	h = read_url(daily_schedule_url)
	completed_series_selector = ".comp>.daily_section>.daily_card>li>a"
	as = eachmatch(Selector(completed_series_selector), h.root)
	map(q->q.attributes["href"], as)
end

# ╔═╡ 4eb2076e-fe90-46e0-843e-be90b62199fb
completed_series_urls = get_all_completed_series_urls(daily_schedule_url)

# ╔═╡ d52c2b93-28e7-40a2-b28b-ff63805d94d0
completed_series_pages = asyncmap(read_url, completed_series_urls)

# ╔═╡ 3a615405-7861-467f-b29a-df0ae80a6789
function get_data_frame()
	df = DataFrame()
	for (name, to_type, selectors) ∈ values_getters
		function getter(page)
			matches = eachmatch(Selector(selectors), page.root)
			@assert(length(matches) == 1, "$(length(matches))")
			@assert(length(matches[1].children) == 1, "$(length(matches.children))")
			matches[1].children[1].text
		end
		df[:, name] = completed_series_pages .|> getter .|> to_type
	end
	df[:, "Url"] = completed_series_urls .|> url -> HTML("<a href=\"$url\">Link</a>")
	sort!(df, rev=true)
end

# ╔═╡ 6a85875f-85f4-468f-916b-ba37002a2351
get_data_frame()

# ╔═╡ Cell order:
# ╠═215ff1a2-d65a-49c3-9a6e-aa394f420342
# ╠═6a85875f-85f4-468f-916b-ba37002a2351
# ╠═3a72039c-97c4-4b64-87f5-eba76879cd24
# ╠═e4bf36f4-8382-437d-8c86-14a6808227dd
# ╠═c17cdcb5-6b4c-4528-a471-304383bd736a
# ╠═4eb2076e-fe90-46e0-843e-be90b62199fb
# ╠═d52c2b93-28e7-40a2-b28b-ff63805d94d0
# ╠═a534f08a-cca2-4456-b77e-9e78c4d3b44f
# ╠═3a615405-7861-467f-b29a-df0ae80a6789
# ╠═3486e367-1e67-4e78-9693-8e53e6907e1f
