function createSymmetricalCostMatrix(xcoords::Vector, ycoords::Vector)
    n = length(xcoords)
    C = zeros(n, n)
    for i in 1:n
        for j in (i+1):n
            d = sqrt((xcoords[i] - xcoords[j])^2 + (ycoords[i] - ycoords[j])^2)
            C[i, j] = d
            C[j, i] = d
        end
    end
    return C
end