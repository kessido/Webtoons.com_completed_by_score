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

# ╔═╡ ac9490eb-1447-4662-a955-b76e22a79f47
md"# Completed"

# ╔═╡ db306e32-94c5-4360-bdcf-19b6346f38d3
md"# All"

# ╔═╡ 3a72039c-97c4-4b64-87f5-eba76879cd24
read_url(url) = url |> HTTP.get |> x -> x.body |> String |> parsehtml

# ╔═╡ e4bf36f4-8382-437d-8c86-14a6808227dd
const daily_schedule_url = "https://www.webtoons.com/en/dailySchedule"

# ╔═╡ 0b7c8808-c6af-4f04-a82b-297cc4e69654
function single_selector(page, selector)
	matches = eachmatch(Selector(selector), page.root)
	@assert(length(matches) == 1, "$(length(matches))")
	matches[1].children |> 
	x->filter(x->typeof(x) != HTMLElement{:br}, x) .|>
	child -> child.text
end

# ╔═╡ e453acd5-804a-47b3-b595-d6835582db33
function get_name(page)
	l = single_selector(page, ".detail_header>.info>.subj")
	join(l, " ")
end

# ╔═╡ 0eb299fa-d46d-4166-904d-5f212f39bf91
function get_genre(page)
	l = single_selector(page, ".detail_header>.info>.genre")
	@assert length(l) == 1
	l[1]
end

# ╔═╡ fa6fec9b-3c29-4e6b-97d7-2a7961bb3806
function get_score(page)
	l = single_selector(page, "#_starScoreAverage")
	@assert length(l) == 1
	parse(Float64, l[1])
end

# ╔═╡ 52bf2979-08d8-41ec-81a3-08880961a314
get_is_completed(page) = !all(isempty.(
							[".txt_ico_completed", ".txt_ico_completed2"] .|>
							selector -> eachmatch(Selector(selector), page.root)
						))

# ╔═╡ cd5f059d-44d5-466e-804f-63d8c516283f
function get_last_chapter(page)
	l = single_selector(page, ".detail_lst>#_listUl>:first-child>a>.tx")
	@assert length(l) == 1
	@assert(l[1][1] == '#', l[1])
	parse(Int, l[1][2:end])
end

# ╔═╡ a534f08a-cca2-4456-b77e-9e78c4d3b44f
values_getters = [
	("Score", get_score),
	("Genre", get_genre),
	("Name", get_name),
	("Completed", get_is_completed),
	("Last Chapter", get_last_chapter),
]

# ╔═╡ 3a615405-7861-467f-b29a-df0ae80a6789
function get_data_frame(series_urls)
	series_pages = asyncmap(read_url, series_urls)
	df = DataFrame()
	for (name, getter) ∈ values_getters
		df[:, name] = getter.(series_pages)
	end
	df[:, "Url"] = series_urls .|> url -> HTML("<a href=\"$url\">Link</a>")
	sort!(df, rev=true)
end

# ╔═╡ 3486e367-1e67-4e78-9693-8e53e6907e1f
function get_all_series_urls(;completed::Bool=false)
	h = read_url(daily_schedule_url)
	series_selector = ".daily_section>.daily_card>li>a"
	completed && (series_selector = ".comp>" * series_selector)
	as = eachmatch(Selector(series_selector), h.root)
	map(q->q.attributes["href"], as) |> unique!
end

# ╔═╡ 2aaaa8e5-3c82-4c46-b1d4-564885531d1f
get_all_series_urls(completed=true) |> get_data_frame

# ╔═╡ 1111481e-7705-402b-92a9-14e39933ca51
get_all_series_urls() |> get_data_frame

# ╔═╡ Cell order:
# ╠═215ff1a2-d65a-49c3-9a6e-aa394f420342
# ╟─ac9490eb-1447-4662-a955-b76e22a79f47
# ╠═2aaaa8e5-3c82-4c46-b1d4-564885531d1f
# ╠═db306e32-94c5-4360-bdcf-19b6346f38d3
# ╠═1111481e-7705-402b-92a9-14e39933ca51
# ╠═3a72039c-97c4-4b64-87f5-eba76879cd24
# ╠═e4bf36f4-8382-437d-8c86-14a6808227dd
# ╠═c17cdcb5-6b4c-4528-a471-304383bd736a
# ╠═0b7c8808-c6af-4f04-a82b-297cc4e69654
# ╠═e453acd5-804a-47b3-b595-d6835582db33
# ╠═0eb299fa-d46d-4166-904d-5f212f39bf91
# ╠═fa6fec9b-3c29-4e6b-97d7-2a7961bb3806
# ╠═52bf2979-08d8-41ec-81a3-08880961a314
# ╠═cd5f059d-44d5-466e-804f-63d8c516283f
# ╠═a534f08a-cca2-4456-b77e-9e78c4d3b44f
# ╠═3a615405-7861-467f-b29a-df0ae80a6789
# ╠═3486e367-1e67-4e78-9693-8e53e6907e1f
