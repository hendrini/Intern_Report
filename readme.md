# NeXtWind Internship Report

This repository contains the internship report and supporting files for my internship at NeXtWind as part of my studies. The report documents the design and implementation of a PostGIS-based geospatial database system to improve the company's spatial data management.

## Abstract

As NeXtWind continues to grow rapidly, the company faces several challenges in its technical infrastructure and data management. In the field of geospatial data, our goal is to provide colleagues with a synchronized, user-friendly system for accessing and managing spatial information.

Previously, wind farm planning relied heavily on printed maps and shapefiles. Data was stored in shared SharePoint folders, and simultaneous file access frequently led to errors and inconsistencies.

The goal of this report is to design and implement a PostGIS-based database that can be accessed through both common SQL query tools and desktop GIS, while also providing a guided introduction on how the system works and how it can be used. The report explains the modeling and implementation processes, outlines possible technical applications, and discusses how the database structure aligns with the company’s practical requirements.

The presented data model and database together form a digital twin of NeXtWind’s wind and energy parks, representing elements such as planned and existing wind turbines, cable routes, relevant land parcels, and administrative boundaries. The model is designed to be scalable, with clearly defined attributes to support flexible analysis, planning, and reporting. Finally, the report demonstrates examples of automation through database triggers and outlines potential directions for future development and system evolution.

## Repository Structure

```
Intern_Report/
├── Figures/                   # Logos, diagrams, and other images used in the report
├── Datamodel/                 # Files defining the database schema
├── SQL/                       # SQL scripts for data insertion, queries, or triggers
├── intern_nextwind.tex        # Main LaTeX source file
├── literatur.bib              # Bibliography file
├── intern_nextwind_signed.pdf # Compiled PDF of the report
└── .gitignore                 # Specifies files to ignore (auxiliary files, build artifacts, etc.)
```

## Compilation

The LaTeX report can be compiled using **TeX Live**. A simple compilation command:

```bash
pdflatex intern_nextwind.tex
bibtex literatur
pdflatex intern_nextwind.tex
pdflatex intern_nextwind.tex
```

Alternatively, `latexmk` can be used for automated compilation:

```bash
latexmk -pdf intern_nextwind.tex
```
