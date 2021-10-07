const regions = ["Africa", "Asia", "Antarctica", "Australia", "Europe", "North America", "South America" ]

export const Region = () => regions[Math.floor(Math.random()*regions.length)];
