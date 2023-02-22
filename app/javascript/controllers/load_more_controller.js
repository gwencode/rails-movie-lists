import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="load-more"
export default class extends Controller {
  static targets = [ "movies", "movie", "button" ]

  connect() {
    this.perPage = 20
    console.log(pageIndex)
  }

  loadMore(event) {
    event.preventDefault()
    pageIndex++
    console.log(pageIndex)
    this.loadPage()
  }

  async loadPage() {
    this.maxMovies = pageIndex * this.perPage

    if (pageIndex >= this.pagesCount) {
      this.updateButton()
    }

    const url =`/movies/parse_movies/?page=${pageIndex}`
    const response = await fetch(url)
    console.log(response)
    const movies = await response.json()
      this.parseMovies(movies);
    }

    parseMovies(movies) {
      console.log(movies)
      movies.forEach(movie => {
        console.log(movie)
      })
      const html = movies.map(movie => {
        return `<div data-load-more-target="movie">
                  <a class="text-decoration-none" href="/movies/${movie.id}">
                    <div class="card-movie">
                      <img src="${movie.poster_url}">
                    </div>
                  </a>
                </div>`;
      }).join('');
      this.moviesTarget.insertAdjacentHTML('beforeend', html);
    }

    updateButton() {
      this.buttonTarget.classList.add("d-none")
    }
  }

  // const url = `/?page=${pageIndex}`
  // const response = await fetch(url)
  // const html = await response.text()
  // console.log(html)
  // const parser = new DOMParser();
  // const doc = parser.parseFromString(html, 'text/html');
  // // console.log(doc)
  // // console.log(this.maxMovies)
  // const movies = doc.querySelectorAll('[data-load-more-target="movie"]');
  // // console.log(movies)
  // movies.forEach((node, index) => {
  //   if (index >= this.maxMovies - this.perPage) {
  //     this.moviesTarget.insertAdjacentElement('beforeend', movies[index]);
  //   }
  // });

  // const endpoint = `/movies/parse_movies/${this.currentPage}`
  // console.log(endpoint)
  // fetch(endpoint)
  //   .then(response => response.json())
  //   .then(movies => {
  //     console.log(movies)
  //   })

  // fetch(`${apiURL}&page=${this.currentPage}`)
  //   .then(response => response.json())
  //   .then(movies => {
  //     console.log(movies['results'])
  //   })
